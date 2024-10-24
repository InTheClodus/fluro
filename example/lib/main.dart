// lib/main.dart

import 'dart:async';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// ==========================
/// == 认证服务开始 ==
/// ==========================

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  /// 模拟登录
  Future<void> login() async {
    // 在实际应用中，您可能需要执行网络请求来验证用户凭据
    await Future.delayed(Duration(seconds: 1));
    _isAuthenticated = true;
    notifyListeners();
  }

  /// 模拟登出
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}

/// ==========================
/// == 认证服务结束 ==
/// ==========================

/// ==========================
/// == 认证服务提供者开始 ==
/// ==========================

class AuthServiceProvider extends InheritedWidget {
  final AuthService authService;

  AuthServiceProvider({
    Key? key,
    required this.authService,
    required Widget child,
  }) : super(key: key, child: child);

  static AuthServiceProvider of(BuildContext context) {
    final AuthServiceProvider? result =
    context.dependOnInheritedWidgetOfExactType<AuthServiceProvider>();
    assert(result != null, 'No AuthServiceProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AuthServiceProvider oldWidget) =>
      authService != oldWidget.authService;
}

/// ==========================
/// == 认证服务提供者结束 ==
/// ==========================

/// ==========================
/// == 页面定义开始 ==
/// ==========================

/// HomePage：公共首页，无需鉴权
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter.appRouter;
    return Scaffold(
      appBar: AppBar(
        title: Text("首页"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('欢迎来到首页！'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                router.navigateTo(context, "/dashboard");
              },
              child: Text("前往仪表盘"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                router.navigateTo(context, "/login");
              },
              child: Text("登录"),
            ),
          ],
        ),
      ),
    );
  }
}

/// LoginPage：登录页面
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;

  void _login() async {
    setState(() {
      _loading = true;
    });

    // 调用 AuthService 进行登录
    AuthService authService = AuthServiceProvider.of(context).authService;
    await authService.login();

    setState(() {
      _loading = false;
    });

    // 登录成功后导航回首页
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("登录"),
        ),
        body: Center(
          child: _loading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _login,
            child: Text("点击登录"),
          ),
        ));
  }
}

/// DashboardPage：需要鉴权才能访问的仪表盘页面
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter.appRouter;
    AuthService authService = AuthServiceProvider.of(context).authService;

    return Scaffold(
      appBar: AppBar(
        title: Text("仪表盘"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              router.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: Text('欢迎来到仪表盘！只有登录用户可以看到。'),
      ),
    );
  }
}

/// NotAuthorizedPage：未授权访问页面
class NotAuthorizedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter.appRouter;
    return Scaffold(
      appBar: AppBar(
        title: Text("未授权"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('您未被授权访问此页面。'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                router.navigateTo(context, "/login");
              },
              child: Text("前往登录"),
            ),
          ],
        ),
      ),
    );
  }
}

/// NotFoundPage：未找到路由页面
class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = FluroRouter.appRouter;
    return Scaffold(
      appBar: AppBar(
        title: Text("404"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('页面未找到！'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                router.navigateTo(context, "/");
              },
              child: Text("返回首页"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================
/// == 页面定义结束 ==
/// ==========================

void main() {
  runApp(MyApp());
}

/// MyApp 类
class MyApp extends StatelessWidget {
  final FluroRouter router = FluroRouter.appRouter;
  final AuthService authService = AuthService();

  MyApp() {
    // 设置未找到路由的处理器
    router.notFoundHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
        return NotFoundPage();
      },
    );

    // 设置未授权访问的处理器
    router.notAuthorizedHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
        return NotAuthorizedPage();
      },
    );

    // 定义全局鉴权中间件
    router.useMiddleware(
      AuthMiddleware(
        authGuard: (BuildContext context, String routeName,
            Map<String, List<String>> parameters) async {
          // 允许公共路由无需鉴权
          List<String> publicRoutes = ["/", "/login"];
          if (publicRoutes.contains(routeName)) {
            return true;
          }
          return authService.isAuthenticated;
        },
      ),
    );

    // 定义仪表盘路由的特定中间件（例如，管理员权限）
    final adminMiddleware = AuthMiddleware(
      authGuard: (BuildContext context, String routeName,
          Map<String, List<String>> parameters) async {
        // 这里可以添加更多复杂的鉴权逻辑，例如检查用户角色
        // 目前仅检查用户是否登录
        return authService.isAuthenticated;
      },
    );

    // 定义首页路由
    router.define(
      "/",
      handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
          return HomePage();
        },
      ),
      transitionType: TransitionType.fadeIn,
    );

    // 定义登录路由
    router.define(
      "/login",
      handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
          return LoginPage();
        },
      ),
      transitionType: TransitionType.fadeIn,

    );

    // 定义仪表盘路由，并添加特定中间件
    router.define(
      "/dashboard",
      handler: Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
          return DashboardPage();
        },
      ),
      transitionType: TransitionType.fadeIn,
      middleware: [adminMiddleware],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthServiceProvider(
      authService: authService,
      child: MaterialApp(
        title: 'Fluro 路由鉴权示例',
        onGenerateRoute: router.generator,
        initialRoute: "/",
      ),
    );
  }
}
