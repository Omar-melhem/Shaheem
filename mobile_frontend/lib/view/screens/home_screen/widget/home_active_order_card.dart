// Home: the authoritative active-order status above the offers (D-A73).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/navigation/current_order_navigation.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/cubit/current_order_cubit.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Shows what Home must not hide about the captain's current order, from
/// the app-level `CurrentOrderCubit`:
///
/// - **Active order** (e.g. after Back from the Current Order page): a
///   short line with «عرض الطلب الحالي», the way back to the order now that
///   it is no longer a tab.
/// - **Lookup failed** (startup, resume or acceptance): an explicit
///   "could not check" line with Retry. A failure is never shown as "no
///   order"; Retry opens Current Order when the server then reports one.
///
/// Nothing is shown while loading, for a confirmed absence, or when the
/// orders backend is not configured (the offers section already says the
/// orders service is not connected).
class HomeActiveOrderCard extends StatelessWidget {
  const HomeActiveOrderCard({super.key});

  Future<void> _retry(BuildContext context) async {
    final state = await context.read<CurrentOrderCubit>().refreshed();
    if (state is CurrentOrderActive && context.mounted) {
      openCurrentOrderPage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<CurrentOrderCubit>().state;

    final (IconData icon, String message, String action, VoidCallback onTap)?
    content = switch (state) {
      CurrentOrderActive(:final order) => (
        PhosphorIconsRegular.mapPin,
        l10n.homeActiveOrderMessage(order.restaurantName),
        l10n.homeActiveOrderOpen,
        () => openCurrentOrderPage(context),
      ),
      CurrentOrderFailure() => (
        PhosphorIconsRegular.warningCircle,
        l10n.homeActiveOrderCheckFailed,
        l10n.retry,
        () => unawaited(_retry(context)),
      ),
      _ => null,
    };
    if (content == null) return const SizedBox.shrink();
    final (icon, message, action, onTap) = content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColor.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
            // The action sits under the message, so long text and large
            // text scales never squeeze it out of the row.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    icon,
                    color: AppColor.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColor.onPrimaryContainer,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppTextButton(
                          label: action,
                          color: AppColor.onPrimaryContainer,
                          onPressed: onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
