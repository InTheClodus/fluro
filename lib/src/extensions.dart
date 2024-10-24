import 'package:flutter/material.dart';

/// 扩展BuildContext以获取路由设置和参数
/// 此扩展允许在任何BuildContext上调用settings和arguments方法，简化了路由信息的访问
extension FluroBuildContextX on BuildContext {

  /// 获取当前路由的设置信息
  /// 此属性通过ModalRoute.of方法检索当前路由的设置信息，便于在应用的任何地方访问路由配置
  RouteSettings? get settings => ModalRoute.of(this)?.settings;

  /// 获取当前路由的参数
  /// 此属性提取当前路由设置中的arguments属性，提供了一种简便的方法来访问路由参数
  Object? get arguments => ModalRoute.of(this)?.settings.arguments;
}
