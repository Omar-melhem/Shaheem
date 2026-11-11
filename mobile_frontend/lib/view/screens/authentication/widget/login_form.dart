// The Login form: username, password and the submit button.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/util/validators/validation_error.dart';
import 'package:mobile_frontend/util/validators/validation_messages.dart';
import 'package:mobile_frontend/view/screens/authentication/cubit/login_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_form_field.dart';

/// Username and password fields plus the Login button, rendered from
/// [LoginCubit] state.
///
/// Owns only UI resources (text controllers and focus nodes). All values,
/// validation and submission go through the Cubit:
/// - Username "Next" moves focus to the password; password "Done" submits.
/// - Fields stay filled and read-only while a submission runs.
/// - Field errors come from the Cubit and clear as soon as the field is
///   edited.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Hides the keyboard, then asks the Cubit to submit.
  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? message(ValidationError? error) =>
        error == null ? null : validationMessage(l10n, error);

    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        final busy = state.isSubmitting || state.status == LoginStatus.success;

        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextFormField(
                controller: _usernameController,
                label: l10n.usernameLabel,
                errorText: message(state.usernameError),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                readOnly: busy,
                startIcon: const Icon(Icons.person_outline),
                onChanged: cubit.usernameChanged,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: l10n.passwordLabel,
                errorText: message(state.passwordError),
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                readOnly: busy,
                startIcon: const Icon(Icons.lock_outline),
                onChanged: cubit.passwordChanged,
                onFieldSubmitted: (_) => _submit(context),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.loginButton,
                expand: true,
                isLoading: busy,
                onPressed: () => _submit(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
