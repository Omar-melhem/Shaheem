// «حسابي»: the captain's name and phone from the signed-in session.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_frontend/helper/money/jod_format.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/app_state/session/app_session_cubit.dart';

/// Name and phone of the authenticated captain, read from the one
/// `AppSessionCubit` (no second user store, no editing, no avatar upload).
/// Missing values show honest fallbacks («الاسم غير متوفر», «رقم الهاتف غير
/// متوفر»); nothing is invented. The phone digits are isolated LTR inside
/// the Arabic RTL page so they keep their order.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = context.select<AppSessionCubit, (String?, String?)>((cubit) {
      final s = cubit.state;
      return s is SessionAuthenticated
          ? (s.user.displayName, s.user.phone)
          : (null, null);
    });
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final name = clean(user.$1);
    final phone = clean(user.$2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: AppColor.surfaceContainer,
              child: Icon(
                Icons.person_outline,
                size: 30,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label:
                        '${l10n.profileNameLabel}: '
                        '${name ?? l10n.profileNameUnavailable}',
                    excludeSemantics: true,
                    child: Text(
                      name ?? l10n.profileNameUnavailable,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: name == null
                            ? AppColor.textSecondary
                            : AppColor.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label:
                        '${l10n.profilePhoneLabel}: '
                        '${phone ?? l10n.profilePhoneUnavailable}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AppColor.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            phone == null
                                ? l10n.profilePhoneUnavailable
                                : ltrIsolate(phone),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
