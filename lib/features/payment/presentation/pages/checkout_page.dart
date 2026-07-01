import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../customer/data/models/address_model.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/bloc/customer_state.dart';
import '../../../customer/presentation/pages/address_list_page.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/payment_bloc.dart';
import '../../../orders/presentation/pages/order_tracking_page.dart';
import '../../data/models/checkout_summary.dart';

// ── Payment method enum ───────────────────────────────────────────────────────

enum _PaymentMethod { cod, razorpay }

// ── Page entry point ──────────────────────────────────────────────────────────

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.cartBloc,
    required this.customerBloc,
  });

  final CartBloc cartBloc;
  final CustomerBloc customerBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cartBloc),
        BlocProvider.value(value: customerBloc),
        BlocProvider(create: (_) => PaymentBloc()),
        BlocProvider(create: (_) => CheckoutCubit()),
      ],
      child: const _CheckoutScaffold(),
    );
  }
}

// ── Scaffold ──────────────────────────────────────────────────────────────────

class _CheckoutScaffold extends StatefulWidget {
  const _CheckoutScaffold();

  @override
  State<_CheckoutScaffold> createState() => _CheckoutScaffoldState();
}

class _CheckoutScaffoldState extends State<_CheckoutScaffold> {
  late final Razorpay _razorpay;
  _PaymentMethod _selectedMethod = _PaymentMethod.cod;

  // Tracks the last address for which we fired the zone API so we only
  // recalculate when the address actually changes (not on every state rebuild).
  int? _lastAddressId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Trigger initial calculation if an address is already selected when
    // the page opens (e.g. user already picked an address in a prior session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final custState = context.read<CustomerBloc>().state;
      final cartState = context.read<CartBloc>().state;
      if (custState is CustomerLoaded &&
          custState.selectedAddress != null &&
          cartState is CartLoaded) {
        _lastAddressId = custState.selectedAddress!.id;
        context.read<CheckoutCubit>().calculate(
              address: custState.selectedAddress!,
              cartItems: cartState.items,
            );
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    final state = context.read<PaymentBloc>().state;
    final appOrderId =
        state is PaymentReadyToCheckout ? state.details.appOrderId : 0;
    context.read<PaymentBloc>().add(PaymentRazorpaySucceeded(
          paymentId: response.paymentId ?? '',
          razorpayOrderId: response.orderId ?? '',
          signature: response.signature ?? '',
          appOrderId: appOrderId,
        ));
  }

  void _onPaymentError(PaymentFailureResponse response) {
    context.read<PaymentBloc>().add(PaymentRazorpayFailed(
          code: response.code ?? 0,
          description: response.message ?? 'Unknown error',
        ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Order actions ─────────────────────────────────────────────────────────

  void _startCOD(
      AddressModel address, CartLoaded cartState, CheckoutSummary summary) {
    context.read<PaymentBloc>().add(PaymentCODStarted(
          address: address,
          cartItems: cartState.items,
          orderAmount: summary.grandTotal,
          deliveryCharge: summary.deliveryCharge,
          taxAmount: summary.tax,
          distance: summary.distanceInKm,
        ));
  }

  void _startRazorpay(CartLoaded cartState, CheckoutSummary summary) {
    final custState = context.read<CustomerBloc>().state;
    final customer = custState is CustomerLoaded ? custState.customer : null;
    context.read<PaymentBloc>().add(PaymentDirectCheckoutStarted(
          amountInPaise: (summary.grandTotal * 100).toInt(),
          razorpayKeyId: 'rzp_test_RxhuvnXFx9l1pB',
          customerName: customer?.fullName,
          customerEmail: customer?.email,
          customerPhone: customer?.phone,
          description: 'World of Rice — ${cartState.totalItems} item(s)',
        ));
  }

  void _onProceed(AddressModel address, CartLoaded cartState) {
    final chkState = context.read<CheckoutCubit>().state;
    if (chkState is! CheckoutReady) return;
    if (_selectedMethod == _PaymentMethod.cod) {
      _startCOD(address, cartState, chkState.summary);
    } else {
      _startRazorpay(cartState, chkState.summary);
    }
  }

  Future<void> _openAddressList(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CustomerBloc>(),
          child: const AddressListPage(),
        ),
      ),
    );
  }

  // ── Recalculate helpers ───────────────────────────────────────────────────

  void _recalculateForAddress(BuildContext ctx, AddressModel address) {
    if (address.id == _lastAddressId) return;
    _lastAddressId = address.id;
    final cartState = ctx.read<CartBloc>().state;
    if (cartState is CartLoaded) {
      ctx.read<CheckoutCubit>().calculate(
            address: address,
            cartItems: cartState.items,
          );
    }
  }

  void _recalculateForCart(BuildContext ctx, CartLoaded cartState) {
    final custState = ctx.read<CustomerBloc>().state;
    if (custState is CustomerLoaded && custState.selectedAddress != null) {
      ctx.read<CheckoutCubit>().calculate(
            address: custState.selectedAddress!,
            cartItems: cartState.items,
          );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentBloc, PaymentState>(
          listener: (ctx, state) {
            if (state is PaymentReadyToCheckout) {
              _razorpay.open(state.details.toRazorpayOptions());
            }
          },
        ),
        // Recalculate whenever the user selects a different delivery address.
        BlocListener<CustomerBloc, CustomerState>(
          listener: (ctx, state) {
            if (state is CustomerLoaded && state.selectedAddress != null) {
              _recalculateForAddress(ctx, state.selectedAddress!);
            }
          },
        ),
        // Recalculate when cart items change (quantity / add / remove).
        BlocListener<CartBloc, CartState>(
          listener: (ctx, state) {
            if (state is CartLoaded && !state.isUpdating) {
              _recalculateForCart(ctx, state);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: _buildAppBar(context),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is! CartLoaded || cartState.items.isEmpty) {
              return Center(
                child: Text('Your cart is empty.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              );
            }
            return BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, payState) =>
                  _buildBody(context, cartState, payState),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: AppColors.darkBrown),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Checkout',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkBrown,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8E0D5)),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, CartLoaded cartState, PaymentState payState) {
    // ── Success screens ──────────────────────────────────────────────────────
    if (payState is PaymentSuccess) {
      return _RazorpaySuccessScreen(
        paymentId: payState.paymentId,
        onDone: () {
          context.read<CartBloc>().add(const CartStarted());
          context.read<PaymentBloc>().add(const PaymentReset());
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      );
    }

    if (payState is OrderPlaced) {
      return _CODSuccessScreen(
        orderId: payState.orderId,
        totalAmount: payState.totalAmount,
        onDone: () {
          context.read<CartBloc>().add(const CartStarted());
          context.read<PaymentBloc>().add(const PaymentReset());
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
        onTrack: () {
          final orderId = payState.orderId;
          context.read<CartBloc>().add(const CartStarted());
          context.read<PaymentBloc>().add(const PaymentReset());
          Navigator.of(context)
            ..popUntil((r) => r.isFirst)
            ..push(MaterialPageRoute(
              builder: (_) => OrderTrackingPage(orderId: orderId),
            ));
        },
      );
    }

    // ── Failure screen ───────────────────────────────────────────────────────
    if (payState is PaymentFailure) {
      return _FailureScreen(
        message: payState.message,
        onRetry: () => context.read<PaymentBloc>().add(const PaymentReset()),
      );
    }

    final isProcessing =
        payState is PaymentLoading || payState is PaymentConfirming;

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, custState) {
        final selectedAddress =
            custState is CustomerLoaded ? custState.selectedAddress : null;
        final hasAddress = selectedAddress != null;

        return Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Bottom padding = CTA bar height (~160) + safe-area inset + 24 breathing room.
              padding: EdgeInsets.fromLTRB(
                16, 16, 16,
                MediaQuery.of(context).viewPadding.bottom + 184,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Step indicator ─────────────────────────────────────
                  _StepIndicator(addressSelected: hasAddress),
                  const SizedBox(height: 20),

                  // ── Deliver To card ────────────────────────────────────
                  _DeliverToCard(
                    address: selectedAddress,
                    onTap: () => _openAddressList(context),
                  ),
                  const SizedBox(height: 16),

                  // ── Order summary ──────────────────────────────────────
                  _OrderSummaryCard(cartState: cartState),
                  const SizedBox(height: 16),

                  // ── Payment method selector ────────────────────────────
                  _SectionCard(
                    title: 'Payment Method',
                    child: Column(
                      children: [
                        _PaymentOption(
                          icon: Icons.money_rounded,
                          iconBg: const Color(0xFF2E7D32),
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when your order arrives',
                          isSelected: _selectedMethod == _PaymentMethod.cod,
                          onTap: () => setState(
                              () => _selectedMethod = _PaymentMethod.cod),
                        ),
                        const Divider(height: 1, color: Color(0xFFF0EAE0)),
                        _PaymentOption(
                          iconWidget: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF072654),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('R',
                                style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                          title: 'Razorpay',
                          subtitle: 'Cards · UPI · Netbanking · Wallets',
                          isSelected:
                              _selectedMethod == _PaymentMethod.razorpay,
                          onTap: () => setState(
                              () => _selectedMethod = _PaymentMethod.razorpay),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Bill summary (dynamic) ─────────────────────────────
                  BlocBuilder<CheckoutCubit, CheckoutState>(
                    builder: (ctx, chkState) => _BillSummaryCard(
                      cartState: cartState,
                      checkoutState: chkState,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Sticky bottom bar (dynamic total + proceed button) ─────────
            BlocBuilder<CheckoutCubit, CheckoutState>(
              builder: (ctx, chkState) => Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CheckoutBar(
                  cartState: cartState,
                  hasAddress: hasAddress,
                  isProcessing: isProcessing,
                  selectedMethod: _selectedMethod,
                  checkoutState: chkState,
                  onProceed: hasAddress &&
                          !isProcessing &&
                          chkState is CheckoutReady
                      ? () => _onProceed(selectedAddress, cartState)
                      : null,
                ),
              ),
            ),

            if (isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primaryGreen),
                        const SizedBox(height: 16),
                        Text(
                          _selectedMethod == _PaymentMethod.cod
                              ? 'Placing your order…'
                              : 'Connecting to Razorpay…',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.addressSelected});
  final bool addressSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(number: '1', label: 'Address', done: addressSelected, active: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: addressSelected
                  ? AppColors.primaryGreen
                  : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _Step(
            number: '2',
            label: 'Payment',
            done: false,
            active: addressSelected),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.done,
    required this.active,
  });
  final String number;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        done || active ? AppColors.primaryGreen : AppColors.borderMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done ? AppColors.primaryGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Center(
                  child: Text(number,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ── Deliver To card ───────────────────────────────────────────────────────────

class _DeliverToCard extends StatelessWidget {
  const _DeliverToCard({required this.address, required this.onTap});
  final AddressModel? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: address != null
                ? AppColors.primaryGreen.withValues(alpha: 0.4)
                : const Color(0xFFE8E0D5),
            width: address != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: address == null ? _noAddress() : _withAddress(address!),
      ),
    );
  }

  Widget _noAddress() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_location_alt_outlined,
              size: 22, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver To',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Select a delivery address',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.primaryGreen, size: 22),
      ],
    );
  }

  Widget _withAddress(AddressModel a) {
    final fullAddr = a.additionalInfo.isNotEmpty
        ? a.additionalInfo
        : [
            if (a.house.isNotEmpty) a.house,
            if (a.floor.isNotEmpty) 'Floor ${a.floor}',
          ].join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_rounded,
              size: 22, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Deliver To',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(a.addressType,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen)),
                  ),
                ],
              ),
              if (a.contactName.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(a.contactName,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown)),
              ],
              if (fullAddr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(fullAddr,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25)),
            ),
            child: Text('Change',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen)),
          ),
        ),
      ],
    );
  }
}

// ── Order summary card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cartState});
  final CartLoaded cartState;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Order Summary',
      child: Column(
        children: [
          for (final item in cartState.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product?.name ?? 'Item',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          '${item.variation.type} × ${item.quantity}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text('₹${item.lineTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bill summary card ─────────────────────────────────────────────────────────

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({
    required this.cartState,
    required this.checkoutState,
  });
  final CartLoaded cartState;
  final CheckoutState checkoutState;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Bill Summary',
      child: switch (checkoutState) {
        CheckoutReady(:final summary) => _readyRows(summary),
        CheckoutCalculating() => _calculatingRows(),
        CheckoutError(:final message) => _errorRow(message),
        CheckoutInitial() => _initialRow(),
      },
    );
  }

  Widget _readyRows(CheckoutSummary s) {
    return Column(
      children: [
        _BillRow(
          label: 'Item Total',
          value: '₹${s.subtotal.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 6),
        _BillRow(
          label: s.tax > 0
              ? 'Tax (5% on ${s.totalWeightKg.toStringAsFixed(1)} kg)'
              : 'Tax (weight ≥ 25 kg)',
          value: s.tax > 0
              ? '(+) ₹${s.tax.toStringAsFixed(0)}'
              : '₹0',
        ),
        const SizedBox(height: 6),
        _BillRow(
          label:
              'Delivery (${s.distanceInKm.toStringAsFixed(1)} km)',
          value: s.deliveryCharge > 0
              ? '(+) ₹${s.deliveryCharge.toStringAsFixed(0)}'
              : 'FREE',
          valueColor:
              s.deliveryCharge == 0 ? AppColors.primaryGreen : null,
        ),
        if (s.discount > 0) ...[
          const SizedBox(height: 6),
          _BillRow(
            label: 'Discount',
            value: '(-) ₹${s.discount.toStringAsFixed(0)}',
            valueColor: AppColors.primaryGreen,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: Color(0xFFF0EAE0)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('To Pay',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown)),
            Text('₹${s.grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen)),
          ],
        ),
      ],
    );
  }

  Widget _calculatingRows() {
    return Column(
      children: [
        _BillRow(
          label: 'Item Total',
          value: '₹${cartState.subtotal.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 8),
            Text('Calculating delivery & tax…',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _errorRow(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillRow(
          label: 'Item Total',
          value: '₹${cartState.subtotal.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 8),
        Text(
          'Could not calculate delivery charges. Please try again.',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.ctaRed),
        ),
      ],
    );
  }

  Widget _initialRow() {
    return Column(
      children: [
        _BillRow(
          label: 'Item Total',
          value: '₹${cartState.subtotal.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 8),
        Text(
          'Select a delivery address to calculate charges.',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

// ── Payment option tile ───────────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    this.icon,
    this.iconBg,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData? icon;
  final Color? iconBg;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            iconWidget ??
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg ?? AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.borderMedium,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Sticky checkout bar ───────────────────────────────────────────────────────

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.cartState,
    required this.hasAddress,
    required this.isProcessing,
    required this.selectedMethod,
    required this.checkoutState,
    required this.onProceed,
  });

  final CartLoaded cartState;
  final bool hasAddress;
  final bool isProcessing;
  final _PaymentMethod selectedMethod;
  final CheckoutState checkoutState;
  final VoidCallback? onProceed;

  @override
  Widget build(BuildContext context) {
    final isCOD = selectedMethod == _PaymentMethod.cod;

    String label;
    if (!hasAddress) {
      label = 'SELECT ADDRESS TO CONTINUE';
    } else if (checkoutState is CheckoutCalculating) {
      label = 'CALCULATING CHARGES…';
    } else if (isProcessing) {
      label = isCOD ? 'Placing Order…' : 'Connecting…';
    } else {
      label = isCOD ? 'PLACE ORDER' : 'PROCEED TO PAY';
    }

    // Show grand total when ready, fallback to subtotal while calculating.
    final displayTotal = checkoutState is CheckoutReady
        ? (checkoutState as CheckoutReady).summary.grandTotal
        : cartState.subtotal;

    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, safeBottom > 0 ? safeBottom + 8 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Row(
                children: [
                  if (checkoutState is CheckoutCalculating) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '₹${displayTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkBrown),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCOD ? AppColors.primaryGreen : AppColors.ctaRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderMedium,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
            ),
          ),
          if (!isCOD) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Secured by Razorpay',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── COD Success screen ────────────────────────────────────────────────────────

class _CODSuccessScreen extends StatelessWidget {
  const _CODSuccessScreen({
    required this.orderId,
    required this.totalAmount,
    required this.onDone,
    required this.onTrack,
  });
  final int orderId;
  final double totalAmount;
  final VoidCallback onDone;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text('Order Placed!',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown)),
            const SizedBox(height: 8),
            Text('Your order has been successfully placed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Order ID', value: '#$orderId'),
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'Amount',
                      value: '₹${totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Payment', value: 'Cash on Delivery'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onTrack,
                icon: const Icon(Icons.location_searching_rounded, size: 18),
                label: Text('TRACK ORDER',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBrown,
                  side: const BorderSide(color: Color(0xFFD5C9B8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('BACK TO HOME',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown)),
      ],
    );
  }
}

// ── Razorpay Success screen ───────────────────────────────────────────────────

class _RazorpaySuccessScreen extends StatelessWidget {
  const _RazorpaySuccessScreen(
      {required this.paymentId, required this.onDone});
  final String paymentId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text('Payment Successful!',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown)),
            const SizedBox(height: 8),
            Text('Your order has been placed.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textSecondary)),
            if (paymentId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Payment ID: $paymentId',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textHint)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('BACK TO HOME',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Failure screen ────────────────────────────────────────────────────────────

class _FailureScreen extends StatelessWidget {
  const _FailureScreen({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.ctaRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  size: 64, color: AppColors.ctaRed),
            ),
            const SizedBox(height: 24),
            Text('Order Failed',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('TRY AGAIN',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Cart',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
