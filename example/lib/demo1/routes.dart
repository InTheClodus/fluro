import 'package:fluro_example/demo1/home.dart';
import 'package:fluro_pro/fluro.dart';
import 'package:flutter/material.dart';

import 'details.dart';

class Routes {
  static String root = "/";
  static String details = "/details/:id";

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      print("ROUTE WAS NOT FOUND !!!");
      return;
    });
    router.define(root, handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return HomePage();
    }));
    router.define(details, handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      return DetailsPage();
    }));
  }
}
