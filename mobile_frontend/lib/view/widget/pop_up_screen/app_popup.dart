// Shared popup/dialog component and its show helper.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/text_themes.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/widget/buttons/app_button.dart';
import 'package:mobile_frontend/view/widget/buttons/app_text_button.dart';

/// One action button in an [AppPopup].
class AppPopupAction {
  const AppPopupAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.closesPopup = true,
  }) : assert(
         closesPopup || onPressed != null,
         'An action that does not close the popup needs onPressed; '
         'otherwise the button does nothing.',
       );

  /// Visible text and accessible name of the button. Localized (ARB).
  final String label;

  /// Runs after the popup closes (when [closesPopup] is true). Null with
  /// [closesPopup] true: the button only closes the popup.
  final VoidCallback? onPressed;

  /// Primary actions render as [AppButton]; others as [AppTextButton].
  final bool isPrimary;

  /// Uses the error color, for irreversible actions.
  final bool isDestructive;

  /// Closes the popup before running [onPressed]. Set false when the
  /// callback manages the popup itself.
  final bool closesPopup;
}

/// The app's standard dialog: optional icon, title, a body ([message] or
/// [content]) and a row of actions. Show it with [showAppPopup]; it is a
/// modal, not a GoRouter page.
///
/// Every part is optional; a popup may be content-only. [message] and
/// [content] are mutually exclusive (assert).
///
/// Layout (see SHARED_UI_COMPONENTS_REFERENCE §3.10):
/// - Width is capped at [maxWidth] so it never stretches on tablets.
/// - Height fits the usable screen: Flutter's [Dialog] already subtracts
///   the keyboard (view insets) and `showDialog` the safe areas, so this
///   widget adds no inset of its own.
/// - Icon, title and body scroll together; the actions stay pinned below
///   them. When even the actions do not fit (e.g. landscape with the
///   keyboard open at a large text size), the actions scroll too and the
///   upper part keeps at least half the height. Text is never shrunk or
///   truncated.
class AppPopup extends StatelessWidget {
  const AppPopup({
    super.key,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.actions = const [],
    this.showCloseButton = false,
    this.maxWidth = 480,
  }) : assert(
         message == null || content == null,
         'Use either message or content.',
       ),
       assert(
         title != null || message != null || content != null,
         'An AppPopup needs a title, a message or content.',
       );

  /// Heading (announced as a header). Null: no title.
  final String? title;

  /// Plain text body, centered. Use [content] for custom widgets instead.
  final String? message;

  /// Custom body widget; scrolls with the title when space is short.
  final Widget? content;

  /// Decorative widget above the title (e.g. an [Icon]).
  final Widget? icon;

  /// Buttons, in order. Primary ones render as [AppButton], others as
  /// [AppTextButton]; destructive ones use `colorScheme.error`. Empty: no
  /// action row.
  final List<AppPopupAction> actions;

  /// Shows a labelled close (X) button at the top end corner.
  final bool showCloseButton;

  /// Upper width bound on larger screens.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);

    void runAction(AppPopupAction action) {
      if (action.closesPopup) navigator.pop();
      action.onPressed?.call();
    }

    final body =
        content ??
        (message == null
            ? null
            : Text(
                message!,
                textAlign: TextAlign.center,
                style: TextThemeStyle.bodyText1.copyWith(
                  color: AppColor.textSecondary,
                  height: 1.5,
                ),
              ));

    final upper = <Widget>[
      if (icon != null) ...[icon!, const SizedBox(height: 12)],
      if (title != null)
        Semantics(
          header: true,
          child: Text(
            title!,
            textAlign: TextAlign.center,
            style: TextThemeStyle.headline5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      if (body != null) ...[
        if (icon != null || title != null) const SizedBox(height: 12),
        body,
      ],
    ];

    final actionBar = actions.isEmpty
        ? null
        : Padding(
            padding: EdgeInsets.only(top: upper.isEmpty ? 0 : 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  action.isPrimary
                      ? AppButton(
                          label: action.label,
                          onPressed: () => runAction(action),
                          backgroundColor: action.isDestructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                        )
                      : AppTextButton(
                          label: action.label,
                          onPressed: () => runAction(action),
                          color: action.isDestructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
              ],
            ),
          );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 16),
              child: _PopupLayout(
                upper: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: upper,
                  ),
                ),
                actions: actionBar == null
                    ? null
                    : SingleChildScrollView(child: actionBar),
              ),
            ),
            if (showCloseButton)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: IconButton(
                  onPressed: navigator.pop,
                  icon: const Icon(Icons.close),
                  tooltip: l10n.close,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows an [AppPopup] as a modal dialog and completes when it closes.
///
/// [barrierDismissible] controls whether tapping outside closes it. A popup
/// that cannot be dismissed must offer an action or the close button, or
/// it could never be closed (assert). Actions close with a null result.
Future<T?> showAppPopup<T>(
  BuildContext context, {
  String? title,
  String? message,
  Widget? content,
  Widget? icon,
  List<AppPopupAction> actions = const [],
  bool showCloseButton = false,
  bool barrierDismissible = true,
}) {
  assert(
    barrierDismissible || showCloseButton || actions.isNotEmpty,
    'A popup that is not barrier-dismissible needs an action or the close '
    'button.',
  );
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppPopup(
      title: title,
      message: message,
      content: content,
      icon: icon,
      actions: actions,
      showCloseButton: showCloseButton,
    ),
  );
}

/// Stacks the scrollable upper part (icon, title, body) above the actions
/// inside the height the [Dialog] allows.
///
/// - Everything fits: both parts get their natural height (the dialog hugs
///   its content, as before).
/// - Too tall: the actions keep their full height (pinned) and the upper
///   part scrolls in what is left.
/// - Even the actions do not fit with half the height left for the upper
///   part: the upper part keeps `min(natural, half)`, and the actions take
///   the rest and scroll.
///
/// Both children are scroll views, so a limited height never overflows.
class _PopupLayout extends MultiChildRenderObjectWidget {
  _PopupLayout({required Widget upper, Widget? actions})
    : super(children: [upper, ?actions]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPopupLayout();
}

class _PopupLayoutParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderPopupLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PopupLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PopupLayoutParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PopupLayoutParentData) {
      child.parentData = _PopupLayoutParentData();
    }
  }

  RenderBox? get _upper => firstChild;
  RenderBox? get _actions => childCount > 1 ? lastChild : null;

  /// Heights for [upper] and [actions] within [maxHeight] (see class doc).
  static (double, double) _split(
    double upperNatural,
    double actionsNatural,
    double maxHeight,
  ) {
    if (upperNatural + actionsNatural <= maxHeight) {
      return (upperNatural, actionsNatural);
    }
    final upperMin = upperNatural < maxHeight / 2
        ? upperNatural
        : maxHeight / 2;
    if (actionsNatural <= maxHeight - upperMin) {
      return (maxHeight - actionsNatural, actionsNatural);
    }
    return (upperMin, maxHeight - upperMin);
  }

  /// Lays out (or dry-lays-out) both children and returns this box's size.
  ///
  /// Pass 1 measures natural sizes with an unbounded height. Pass 2 gives
  /// both children the same width (the widest one, so each is centered
  /// like the old column) and the heights from [_split].
  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild) {
    final upper = _upper!;
    final actions = _actions;
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final upperNatural = layoutChild(upper, loose);
    final actionsNatural = actions == null
        ? Size.zero
        : layoutChild(actions, loose);

    final width = constraints.constrainWidth(
      upperNatural.width > actionsNatural.width
          ? upperNatural.width
          : actionsNatural.width,
    );
    final (upperHeight, actionsHeight) = constraints.hasBoundedHeight
        ? _split(
            upperNatural.height,
            actionsNatural.height,
            constraints.maxHeight,
          )
        : (upperNatural.height, actionsNatural.height);

    final upperSize = layoutChild(
      upper,
      BoxConstraints.tightFor(width: width).copyWith(maxHeight: upperHeight),
    );
    final actionsSize = actions == null
        ? Size.zero
        : layoutChild(
            actions,
            BoxConstraints.tightFor(
              width: width,
            ).copyWith(maxHeight: actionsHeight),
          );
    return constraints.constrain(
      Size(width, upperSize.height + actionsSize.height),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
    (_upper!.parentData! as _PopupLayoutParentData).offset = Offset.zero;
    final actions = _actions;
    if (actions != null) {
      (actions.parentData! as _PopupLayoutParentData).offset = Offset(
        0,
        _upper!.size.height,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _maxOfChildren((c) => c.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _maxOfChildren((c) => c.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _sumOfChildren((c) => c.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _sumOfChildren((c) => c.getMaxIntrinsicHeight(width));

  double _maxOfChildren(double Function(RenderBox) measure) {
    var result = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final v = measure(c);
      if (v > result) result = v;
    }
    return result;
  }

  double _sumOfChildren(double Function(RenderBox) measure) {
    var result = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      result += measure(c);
    }
    return result;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
