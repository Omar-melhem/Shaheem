// Login screen: composition of logo, heading, form and forgot-password.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/images.dart';
import 'package:mobile_frontend/util/responsive/app_breakpoints.dart';
import 'package:mobile_frontend/util/tools/tools.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/screens/authentication/widget/forgot_password_popup.dart';
import 'package:mobile_frontend/view/screens/authentication/widget/login_failure_message.dart';
import 'package:mobile_frontend/view/screens/authentication/widget/login_form.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:mobile_frontend/view/widget/toast/app_toast.dart';

/// Username/password sign-in.
///
/// Expects a [LoginCubit] above it (provided by the `/login` route). This
/// file only composes the layout and turns submission failures into error
/// toasts; field errors are shown inline by [LoginForm]. It never navigates:
/// a successful sign-in authenticates the session and the router opens Home.
///
/// Layout: scrolls when the keyboard is open or the screen is short, and
/// keeps the form at a comfortable width on tablets and desktops
/// ([AppBreakpoints.formMaxWidth]). Tapping outside a field hides the
/// keyboard.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<LoginCubit, LoginState>(
      // A new failure (even the same kind again) shows a toast once.
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.failureCount != previous.failureCount,
      listener: (context, state) => showAppToast(
        context,
        message: loginFailureMessage(l10n, state.failure!),
        type: AppToastType.error,
      ),
      child: GestureDetector(
        onTap: () => appTools.unFocusKeyboard(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppBreakpoints.screenPadding(context),
                  vertical: 24,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppBreakpoints.formMaxWidth(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          AppImages.logo,
                          width: 180,
                          fit: BoxFit.contain,
                          semanticLabel: l10n.appName,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.loginTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColor.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const LoginForm(),
                      const SizedBox(height: 32),
                      Align(
                        alignment: AlignmentDirectional.center,
                        child: AppTextButton(
                          label: l10n.forgotPassword,
                          onPressed: () => showForgotPasswordPopup(context),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
