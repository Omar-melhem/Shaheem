// Material-style loading indicator used by `AppTools.showLoading`.

import 'package:flutter/material.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/view/widget/padding/padding.dart';

/// Brand-colored circular spinner with a "loading…" caption underneath.
///
/// Meant to sit inside a [Dialog] (that is how `AppTools.showLoading` shows
/// it on Android and every non-Apple platform). It uses only Material
/// widgets, so it renders on any platform.
class AndroidLoading extends StatelessWidget {
  const AndroidLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CustomePadding(
          bottom: 10,
          child: CircularProgressIndicator(color: AppColor.primary),
        ),
        // Localized caption (was the English 'loading...').
        Text(context.l10n.loading),
      ],
    ),
  );
}
