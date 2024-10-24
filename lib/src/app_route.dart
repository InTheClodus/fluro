/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 *
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';

import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';

/// The type of transition to use when pushing/popping a route.
///
/// [TransitionType.custom] must also provide a transition when used.
enum TransitionType {
  native,
  nativeModal,
  inFromLeft,
  inFromTop,
  inFromRight,
  inFromBottom,
  fadeIn,
  custom,
  material,
  materialFullScreenDialog,
  cupertino,
  cupertinoFullScreenDialog,
  none,
}

/// A middleware function to be executed before route navigation.
typedef AuthGuard = FutureOr<bool> Function(
    BuildContext context,
    String routeName,
    Map<String, List<String>> parameters,
    );

/// Middleware class for route authentication.
class AuthMiddleware {
  final AuthGuard authGuard;

  AuthMiddleware({required this.authGuard});
}

/// A route that is added to the router tree.
class AppRoute {
  AppRoute(
      this.route,
      this.handler, {
        this.transitionType,
        this.transitionDuration,
        this.transitionBuilder,
        this.opaque,
        this.middleware = const [],
      });

  String route;
  dynamic handler;
  TransitionType? transitionType;
  Duration? transitionDuration;
  RouteTransitionsBuilder? transitionBuilder;
  bool? opaque;
  List<AuthMiddleware> middleware; // New field
}
