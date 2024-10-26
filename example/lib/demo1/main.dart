import 'package:fluro_pro/fluro.dart';
import 'package:flutter/material.dart';

import 'application.dart';
import 'routes.dart';


void main() {
  // 定义和配置路由
  final router = FluroRouter();
  Routes.configureRoutes(router);
  Application.router = router;
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: Application.router.generator,
      initialRoute: Routes.root,


    );
  }
}

