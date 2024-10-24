import 'dart:async';
import 'package:flutter/widgets.dart';

/// 路由切换时使用的过渡类型。
///
/// 当使用[TransitionType.custom]时，也必须提供一个过渡效果。
enum TransitionType {
  native, // 原生过渡
  nativeModal, // 原生模态过渡
  inFromLeft, // 从左侧进入
  inFromTop, // 从顶部进入
  inFromRight, // 从右侧进入
  inFromBottom, // 从底部进入
  fadeIn, // 淡入效果
  custom, // 自定义过渡
  material, // Material风格过渡
  materialFullScreenDialog, // Material风格全屏对话框过渡
  cupertino, // Cupertino风格过渡
  cupertinoFullScreenDialog, // Cupertino风格全屏对话框过渡
  none, // 无过渡效果
}

/// 在路由导航之前执行的身份验证中间件函数。
typedef FluroProGuard = FutureOr<bool> Function(
    BuildContext context,
    String routeName,
    Map<String, List<String>> parameters,
    );

/// 路由身份验证的中间件类。
class FluroProMiddleware {
  final FluroProGuard authGuard;

  FluroProMiddleware({required this.authGuard});
}

/// 添加到路由树中的路由。
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

  String route; // 路由路径
  dynamic handler; // 路由处理器
  TransitionType? transitionType; // 过渡类型
  Duration? transitionDuration; // 过渡持续时间
  RouteTransitionsBuilder? transitionBuilder; // 过渡构建器
  bool? opaque; // 是否不透明
  List<FluroProMiddleware> middleware; // 中间件列表，用于身份验证等
}
