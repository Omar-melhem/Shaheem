// Navigation helper shared by the features that open Current Order.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/util/routes/routes_string.dart';

/// Opens the Current Order page above the current authenticated page, or
/// does nothing when it is already the visible page (no duplicate page and
/// no route loop).
///
/// Shared by the new-offer sheet host (after a confirmed acceptance or a
/// recovered active order) and Home's active-order card (R05, ARCH-04:
/// moved out of `new_offer_sheet_host.dart` without a behavior change). It
/// only navigates: whether an order is active is decided by
/// `CurrentOrderCubit`, and the route stays protected by `resolveRedirect`.
void openCurrentOrderPage(BuildContext context) {
  final router = GoRouter.of(context);
  // The top route (a pushed page does not change the URI below it).
  if (router.state.matchedLocation == RoutesString.currentOrder) return;
  unawaited(router.push(RoutesString.currentOrder));
}
