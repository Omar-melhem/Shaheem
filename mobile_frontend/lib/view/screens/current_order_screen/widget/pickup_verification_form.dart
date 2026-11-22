// Current Order: the pickup-verification form (four-digit merchant PIN).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/util/validators/validation_messages.dart';
import 'package:mobile_frontend/util/validators/validators.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/order_command_notice.dart';
import 'package:mobile_frontend/view/widget/pop_up_screen/app_popup.dart';
import 'package:mobile_frontend/view/widget/text_field/app_text_form_field.dart';

/// Opens the pickup-verification form for [orderId] in the shared
/// [AppPopup]. «تأكيد الاستلام» and «إلغاء» are the popup's own **pinned
/// actions**, so they stay reachable with the keyboard open and at large
/// text while the body scrolls (the AppPopup layout contract). Closing it
/// in any way changes nothing on the order; only a server-confirmed pickup
/// closes it with the new stage.
Future<void> showPickupVerificationForm(
  BuildContext context, {
  required String orderId,
}) {
  final l10n = context.l10n;
  final cubit = context.read<CurrentOrderCubit>();
  final form = GlobalKey<PickupVerificationFormState>();
  // A previous wrong-code message is not carried into a new form (the
  // server keeps counting attempts; nothing is reset).
  cubit.clearCommandFeedback();
  return showAppPopup<void>(
    context,
    title: l10n.pickupVerificationTitle,
    content: BlocProvider.value(
      value: cubit,
      child: PickupVerificationForm(key: form, orderId: orderId),
    ),
    actions: [
      AppPopupAction(label: l10n.cancel),
      AppPopupAction(
        label: l10n.pickupVerificationSubmit,
        isPrimary: true,
        // Stays open: the form validates, the Cubit sends (once; a second
        // tap while sending is ignored) and the form closes on success.
        closesPopup: false,
        onPressed: () => form.currentState?.submit(),
      ),
    ],
  ).whenComplete(cubit.clearCommandFeedback);
}

/// The PIN field and the server's answer; the popup's actions submit or
/// cancel it ([PickupVerificationFormState.submit]).
///
/// Only the syntax is checked here (four digits after Arabic-digit
/// normalization, leading zeros kept); a malformed value sends nothing. The
/// typed PIN lives only in this widget's controller: it is cleared after a
/// rejected attempt and disposed with the form; it is never put in Cubit
/// state, logs or analytics. The form closes itself when the order's stage
/// leaves the pickup leg or the order is no longer the same one.
class PickupVerificationForm extends StatefulWidget {
  const PickupVerificationForm({super.key, required this.orderId});

  /// The order this challenge belongs to.
  final String orderId;

  @override
  State<PickupVerificationForm> createState() => PickupVerificationFormState();
}

/// State of [PickupVerificationForm]; [submit] is the popup's primary
/// action.
class PickupVerificationFormState extends State<PickupVerificationForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  /// Validates the syntax and asks the Cubit to send the PIN. Nothing is
  /// sent while a command runs, after a lock or before reconciliation (the
  /// Cubit enforces it too).
  void submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(
      context.read<CurrentOrderCubit>().confirmPickup(_controller.text),
    );
  }

  /// Whether this form still belongs to the shown pickup challenge.
  bool _stillPickup(CurrentOrderState state) =>
      state is CurrentOrderActive &&
      state.order.orderId == widget.orderId &&
      state.order.leg == ActiveOrderLeg.pickup;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CurrentOrderCubit, CurrentOrderState>(
      listener: (context, state) {
        if (!_stillPickup(state)) {
          // Confirmed pickup (or the order changed): close, keep nothing.
          _controller.clear();
          if (ModalRoute.of(context)?.isCurrent ?? false) _close();
          return;
        }
        final command = (state as CurrentOrderActive).command;
        if (command?.error == OrderCommandError.incorrectPin) {
          _controller.clear();
        }
      },
      builder: (context, state) {
        final active = state is CurrentOrderActive ? state : null;
        final command =
            active?.command?.action == OrderWorkflowAction.confirmPickup
            ? active!.command
            : null;
        final sending = command?.sending ?? false;
        final blocked =
            command?.error == OrderCommandError.pinLocked ||
            (command?.needsReconciliation ?? false);
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pickupVerificationMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColor.textSecondary),
              ),
              const SizedBox(height: 16),
              AppTextFormField(
                label: l10n.pickupPinLabel,
                controller: _controller,
                enabled: !sending && !blocked,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                // Digits are entered left to right inside the RTL page.
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  // Digits only (Latin and Arabic-Indic); normalized later.
                  FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹]')),
                  LengthLimitingTextInputFormatter(Validators.pickupPinDigits),
                ],
                validator: (value) {
                  final error = Validators.pickupPin(value);
                  return error == null ? null : validationMessage(l10n, error);
                },
                onFieldSubmitted: (_) => submit(),
              ),
              if (command != null)
                OrderCommandNotice(
                  feedback: command,
                  onCheckStatus: () {
                    _close();
                    unawaited(
                      context.read<CurrentOrderCubit>().checkCommandStatus(),
                    );
                  },
                ),
              if (sending) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.pickupVerificationSending,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }
}
