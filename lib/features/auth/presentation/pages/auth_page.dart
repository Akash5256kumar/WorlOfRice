import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../data/repositories/rest_auth_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_form.dart';

/// The tabbed authentication page (Login / Sign Up).
///
/// - Provides [AuthBloc] via [BlocProvider].
/// - Reacts to [AuthSuccess] / [AuthFailure] via [BlocListener].
/// - Zero business logic — everything lives in [AuthBloc].
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialTab = 0});

  /// 0 = Login tab, 1 = Sign Up tab.
  final int initialTab;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authUseCase: RestAuthUseCase()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: _onAuthStateChanged,
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXXL,
                vertical: AppDimensions.spaceXXL,
              ),
              child: _AuthCard(
                tabController: _tabController,
                onSwitchTab: _switchTab,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      if (state.isSignUp) {
        // After registration: switch to Login tab. The success banner is shown
        // inline by the form; a brief snackbar confirms the action.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        _tabController.animateTo(0);
        context.read<AuthBloc>().add(const AuthErrorDismissed());
      } else {
        Future.microtask(() {
          if (context.mounted) context.go(AppRoutes.home);
        });
      }
    }
    // AuthFailure is handled inline by each form — no snackbar needed here.
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.tabController,
    required this.onSwitchTab,
  });

  final TabController tabController;
  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppDimensions.space32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXXL,
        AppDimensions.spaceXXL,
        AppDimensions.spaceXXL,
        AppDimensions.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: AppDimensions.logoSizeSmall), // 112px — React: w-28 h-28
          const SizedBox(height: AppDimensions.spaceXXL),
          _AuthTabBar(controller: tabController),
          const SizedBox(height: AppDimensions.spaceXXL),
          _AuthTabViews(
            controller: tabController,
            onSwitchTab: onSwitchTab,
          ),
        ],
      ),
    );
  }
}

class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: const [
        Tab(text: AppStrings.login),
        Tab(text: AppStrings.signUp),
      ],
    );
  }
}

class _AuthTabViews extends StatelessWidget {
  const _AuthTabViews({
    required this.controller,
    required this.onSwitchTab,
  });

  final TabController controller;
  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    // Use a fixed-height TabBarView to work inside SingleChildScrollView.
    return SizedBox(
      height: _estimatedFormHeight(controller),
      child: TabBarView(
        controller: controller,
        children: [
          LoginForm(onSwitchToSignUp: () => onSwitchTab(1)),
          SignUpForm(onSwitchToLogin: () => onSwitchTab(0)),
        ],
      ),
    );
  }

  /// Returns the height that fits the taller of the two tabs (sign-up).
  /// Sign-up has 5 fields; at max error state ~840 px.
  /// 960 gives safe headroom without wasting space.
  double _estimatedFormHeight(TabController controller) => 960.0;
}
