import 'dart:async';
import 'package:fluro_pro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


/// {@template fluro_router}
/// 通过将 [FluroRouter.generator] 连接到 [MaterialApp.onGenerateRoute]，将 [FluroRouter] 附加到 [MaterialApp]。
///
/// 使用 [FluroRouter.define] 定义路由，您可以选择性地指定过渡类型，并将字符串路径参数连接到屏幕小部件的构造函数。
///
/// 使用 [FluroRouter.appRouter.navigateTo] 推送新的路由路径，或者如果您更愿意，可以继续使用 [Navigator.of(context).push]。
/// {@endtemplate}
class FluroRouter {
  /// 静态/单例的 [FluroRouter] 实例
  ///
  /// {@macro fluro_router}
  static final appRouter = FluroRouter();

  /// 存储已定义路由的树结构
  final _routeTree = RouteTree();

  /// 当没有定义的路由时的通用处理程序
  Handler? notFoundHandler;

  /// 未授权访问的处理程序
  Handler? notAuthorizedHandler;

  /// 应用于所有路由的全局中间件
  final List<FluroProMiddleware> globalMiddleware = [];

  /// Fluro 全局默认使用的过渡持续时间
  static const defaultTransitionDuration = Duration(milliseconds: 250);
  FutureOr<List<String>> Function(BuildContext context)? defaultGetUserRoles;
  FutureOr<List<String>> Function(BuildContext context)? defaultGetUserPermissions;

  /// 为传递的 [RouteHandler] 创建 [PageRoute] 定义。您可以选择提供默认的过渡类型。
  void define(
    String routePath, {
    required Handler handler,
    TransitionType? transitionType,
    Duration transitionDuration = defaultTransitionDuration,
    RouteTransitionsBuilder? transitionBuilder,
    bool? opaque,
    List<FluroProMiddleware> middleware = const [],
  }) {
    _routeTree.addRoute(
      AppRoute(
        routePath,
        handler,
        transitionType: transitionType,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        opaque: opaque,
        middleware: middleware,
      ),
    );
  }

  /// 为路径值查找已定义的 [AppRoute]。如果没有找到 [AppRoute] 定义，则该函数将返回 null。
  AppRouteMatch? match(String path) {
    return _routeTree.matchRoute(path);
  }

  /// 类似于 [Navigator.pop]
  void pop<T>(BuildContext context, [T? result]) =>
      Navigator.of(context).pop(result);

  /// 添加全局中间件
  void useMiddleware(FluroProMiddleware middleware) {
    globalMiddleware.add(middleware);
  }

  /// 类似于 [Navigator.push] 但带有一些额外功能。
  Future navigateTo(
    BuildContext context,
    String path, {
    bool replace = false,
    bool clearStack = false,
    bool maintainState = true,
    bool rootNavigator = false,
    TransitionType? transition,
    Duration? transitionDuration,
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? routeSettings,
    bool? opaque,
  }) async {
    RouteMatch routeMatch = matchRoute(
      context,
      path,
      transitionType: transition,
      transitionsBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      maintainState: maintainState,
      routeSettings: routeSettings,
      opaque: opaque,
    );

    Route<dynamic>? route = routeMatch.route;

    if (routeMatch.matchType == RouteMatchType.nonVisual) {
      return Future.value("非可视路由类型。");
    } else {
      if (route == null && notFoundHandler != null) {
        route = _notFoundRoute(context, path, maintainState: maintainState);
      }

      if (route != null) {
        // 执行全局中间件
        for (var middleware in globalMiddleware) {
          bool canProceed = await middleware.guard(
            context,
            path,
            routeMatch.parameters,
          );
          if (!canProceed && context.mounted) {
            // 处理未授权访问
            return _handleUnauthorized(context);
          }
        }

        // 执行特定路由的中间件
        if (routeMatch.appRoute != null && context.mounted) {
          for (var middleware in routeMatch.appRoute!.middleware) {
            bool canProceed = await middleware.guard(
              context,
              path,
              routeMatch.parameters,
            );
            if (!canProceed && context.mounted) {
              // 处理未授权访问
              return _handleUnauthorized(context);
            }
          }
        }

        if (routeMatch.appRoute?.roleCheckMiddleware != null) {
          bool hasRole = await routeMatch.appRoute!.roleCheckMiddleware!(
            context,
            path,
            routeMatch.parameters,
          );
          if (!hasRole && context.mounted) {
            return _handleUnauthorized(context);
          }
        }

        // **Execute custom permission check middleware if provided**
        if (routeMatch.appRoute?.permissionCheckMiddleware != null) {
          bool hasPermission = await routeMatch.appRoute!.permissionCheckMiddleware!(
            context,
            path,
            routeMatch.parameters,
          );
          if (!hasPermission && context.mounted) {
            return _handleUnauthorized(context);
          }
        }

        // **Execute global middleware**
        for (var middleware in globalMiddleware) {
          bool canProceed = await middleware.guard(
            context,
            path,
            routeMatch.parameters,
          );
          if (!canProceed && context.mounted) {
            return _handleUnauthorized(context);
          }
        }

        // **Execute route-specific middleware**
        if (routeMatch.appRoute != null && context.mounted) {
          for (var middleware in routeMatch.appRoute!.middleware) {
            bool canProceed = await middleware.guard(
              context,
              path,
              routeMatch.parameters,
            );
            if (!canProceed && context.mounted) {
              return _handleUnauthorized(context);
            }
          }
        }

        if (!context.mounted) return;
        final navigator = Navigator.of(context, rootNavigator: rootNavigator);
        if (clearStack) {
          return navigator.pushAndRemoveUntil(route, (check) => false);
        } else {
          return replace
              ? navigator.pushReplacement(route)
              : navigator.push(route);
        }
      } else {
        final error = "No registered route was found to handle '$path'.";
        debugPrint(error);
        return Future.error(RouteNotFoundException(error, path));
      }
    }
  }

  Route<Null> _notFoundRoute(
    BuildContext context,
    String path, {
    bool? maintainState,
  }) {
    creator(
      RouteSettings? routeSettings,
      Map<String, List<String>> parameters,
    ) {
      return MaterialPageRoute<Null>(
        settings: routeSettings,
        maintainState: maintainState ?? true,
        builder: (BuildContext context) {
          return notFoundHandler?.handlerFunc(context, parameters) ??
              const SizedBox.shrink();
        },
      );
    }

    return creator(RouteSettings(name: path), {});
  }

  Future _handleUnauthorized(BuildContext context) {
    if (notAuthorizedHandler != null) {
      // 使用 notAuthorizedHandler 创建一个路由
      Route<dynamic> notAuthorizedRoute = MaterialPageRoute<dynamic>(
        builder: (BuildContext context) {
          return notAuthorizedHandler!.handlerFunc(context, {}) ??
              const SizedBox.shrink();
        },
      );
      return Navigator.of(context).push(notAuthorizedRoute);
    } else {
      // 返回错误或导航到默认登录页面
      return Future.error("未授权");
    }
  }

  /// 尝试将路由与提供的 [path] 匹配。
  RouteMatch matchRoute(
    BuildContext? buildContext,
    String? path, {
    RouteSettings? routeSettings,
    TransitionType? transitionType,
    Duration? transitionDuration,
    RouteTransitionsBuilder? transitionsBuilder,
    bool maintainState = true,
    bool? opaque,
  }) {
    RouteSettings settingsToUse = routeSettings ?? RouteSettings(name: path);

    if (settingsToUse.name == null) {
      settingsToUse = settingsToUse.copyWithShim(name: path);
    }

    AppRouteMatch? match = _routeTree.matchRoute(path!);
    AppRoute? route = match?.route;

    if (transitionDuration == null && route?.transitionDuration != null) {
      transitionDuration = route?.transitionDuration;
    }

    Handler handler = (route != null ? route.handler : notFoundHandler)!;
    TransitionType? transition = transitionType;

    if (transitionType == null) {
      transition = route != null ? route.transitionType : TransitionType.native;
    }

    if (route == null && notFoundHandler == null) {
      return RouteMatch(
        matchType: RouteMatchType.noMatch,
        errorMessage: "没有找到匹配的路由",
      );
    }

    final parameters = match?.parameters ?? <String, List<String>>{};

    if (handler.type == HandlerType.function) {
      handler.handlerFunc(buildContext, parameters);
      return RouteMatch(matchType: RouteMatchType.nonVisual);
    }

    creator(
      RouteSettings? routeSettings,
      Map<String, List<String>> parameters,
    ) {
      bool isNativeTransition = (transition == TransitionType.native ||
          transition == TransitionType.nativeModal);

      if (isNativeTransition) {
        return MaterialPageRoute<dynamic>(
          settings: routeSettings,
          fullscreenDialog: transition == TransitionType.nativeModal,
          maintainState: maintainState,
          builder: (BuildContext context) {
            return handler.handlerFunc(context, parameters) ??
                const SizedBox.shrink();
          },
        );
      } else if (transition == TransitionType.material ||
          transition == TransitionType.materialFullScreenDialog) {
        return MaterialPageRoute<dynamic>(
          settings: routeSettings,
          fullscreenDialog:
              transition == TransitionType.materialFullScreenDialog,
          maintainState: maintainState,
          builder: (BuildContext context) {
            return handler.handlerFunc(context, parameters) ??
                const SizedBox.shrink();
          },
        );
      } else if (transition == TransitionType.cupertino ||
          transition == TransitionType.cupertinoFullScreenDialog) {
        return CupertinoPageRoute<dynamic>(
          settings: routeSettings,
          fullscreenDialog:
              transition == TransitionType.cupertinoFullScreenDialog,
          maintainState: maintainState,
          builder: (BuildContext context) {
            return handler.handlerFunc(context, parameters) ??
                const SizedBox.shrink();
          },
        );
      } else {
        RouteTransitionsBuilder? routeTransitionsBuilder;

        if (transition == TransitionType.custom) {
          routeTransitionsBuilder =
              transitionsBuilder ?? route?.transitionBuilder;
        } else {
          routeTransitionsBuilder = _standardTransitionsBuilder(transition);
        }

        return PageRouteBuilder<dynamic>(
          opaque: opaque ?? route?.opaque ?? true,
          settings: routeSettings,
          maintainState: maintainState,
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return handler.handlerFunc(context, parameters) ??
                const SizedBox.shrink();
          },
          transitionDuration: transition == TransitionType.none
              ? Duration.zero
              : (transitionDuration ??
                  route?.transitionDuration ??
                  defaultTransitionDuration),
          reverseTransitionDuration: transition == TransitionType.none
              ? Duration.zero
              : (transitionDuration ??
                  route?.transitionDuration ??
                  defaultTransitionDuration),
          transitionsBuilder: transition == TransitionType.none
              ? (_, __, ___, child) => child
              : routeTransitionsBuilder!,
        );
      }
    }

    return RouteMatch(
      matchType: RouteMatchType.visual,
      route: creator(settingsToUse, parameters),
      appRoute: route,
      parameters: parameters,
    );
  }

  RouteTransitionsBuilder _standardTransitionsBuilder(
      TransitionType? transitionType) {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      if (transitionType == TransitionType.fadeIn) {
        return FadeTransition(opacity: animation, child: child);
      } else {
        const topLeft = Offset(0.0, 0.0);
        const topRight = Offset(1.0, 0.0);
        const bottomLeft = Offset(0.0, 1.0);

        var startOffset = bottomLeft;
        var endOffset = topLeft;

        if (transitionType == TransitionType.inFromLeft) {
          startOffset = const Offset(-1.0, 0.0);
          endOffset = topLeft;
        } else if (transitionType == TransitionType.inFromRight) {
          startOffset = topRight;
          endOffset = topLeft;
        } else if (transitionType == TransitionType.inFromBottom) {
          startOffset = bottomLeft;
          endOffset = topLeft;
        } else if (transitionType == TransitionType.inFromTop) {
          startOffset = const Offset(0.0, -1.0);
          endOffset = topLeft;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: startOffset,
            end: endOffset,
          ).animate(animation),
          child: child,
        );
      }
    };
  }

  /// 路由生成方法。此函数可用于在找到任何已定义的处理程序时动态创建路由。
  /// 它也可以用作 [MaterialApp.onGenerateRoute] 属性的回调，以创建可以与 [Navigator] 类一起使用的路由。
  Route<dynamic>? generator(RouteSettings routeSettings) {
    RouteMatch match = matchRoute(
      null,
      routeSettings.name,
      routeSettings: routeSettings,
    );

    return match.route;
  }

  /// 打印路由树以供分析。
  void printTree() {
    _routeTree.printTree();
  }
  // Optional default role and permission check middleware
  FluroProGuard defaultRoleCheckMiddleware(List<String> requiredRoles) {
    return (context, routeName, parameters) async {
      if (defaultGetUserRoles == null) return true; // Allow if no default function is provided
      final userRoles = await defaultGetUserRoles!(context);
      return hasRequiredRoles(requiredRoles, userRoles);
    };
  }

  FluroProGuard defaultPermissionCheckMiddleware(List<String> requiredPermissions) {
    return (context, routeName, parameters) async {
      if (defaultGetUserPermissions == null) return true; // Allow if no default function is provided
      final userPermissions = await defaultGetUserPermissions!(context);
      return hasRequiredPermissions(requiredPermissions, userPermissions);
    };
  }
  bool hasRequiredRoles(List<String> requiredRoles, List<String> userRoles) {
    return requiredRoles.any((role) => userRoles.contains(role));
  }

  bool hasRequiredPermissions(List<String> requiredPermissions, List<String> userPermissions) {
    return requiredPermissions.any((perm) => userPermissions.contains(perm));
  }
}

extension on RouteSettings {
  // 3.5.0 破坏性更改的补丁
  // 忽略: unused_element
  RouteSettings copyWithShim({String? name, Object? arguments}) {
    return RouteSettings(
      name: name ?? this.name,
      arguments: arguments ?? this.arguments,
    );
  }
}
