# 使用文档：Fluro 路由库的增强版（带路由鉴权功能）

本使用文档旨在帮助您理解和使用修改后的 Fluro 路由库，该版本添加了路由鉴权功能，允许您在导航之前执行全局或特定路由的鉴权检查。本文将介绍如何设置路由器、定义路由、添加中间件，以及如何在您的 Flutter 应用中使用这些功能。

---

## 目录

1. [简介](#简介)
2. [安装](#安装)
3. [快速开始](#快速开始)
4. [定义路由](#定义路由)
5. [中间件与鉴权](#中间件与鉴权)
    - [全局中间件](#全局中间件)
    - [路由特定的中间件](#路由特定的中间件)
    - [未授权处理程序](#未授权处理程序)
6. [导航](#导航)
7. [示例代码](#示例代码)
8. [注意事项](#注意事项)
9. [结论](#结论)

---

## 简介

Fluro 是一个 Flutter 的路由库，提供了简单灵活的路由管理方式。该增强版在原有功能的基础上，添加了路由鉴权的支持，通过中间件机制，您可以在导航到某个路由之前执行自定义的鉴权逻辑，以控制用户访问特定页面的权限。

---

## 安装

将代码下载到本地，在项目中建立一个packages目录，将 Fluro 代码解压并放入其中，然后添加到您的依赖中：

```yaml
dependencies:
  flutter:
    sdk: flutter
  fluro:
    path: packages/fluro # 请将此路径替换为您的实际路径
```

然后在终端中运行：

```bash
flutter pub get
```

---

## 快速开始

在开始之前，确保您已经在项目中导入了 Fluro 路由库：

```dart
import 'package:fluro/fluro.dart';
```

### 1. 创建路由器实例

```dart
final router = FluroRouter();
```

### 2. 定义路由

使用 `define` 方法来定义路由。

```dart
router.define(
  "/home",
  handler: Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
      return HomePage();
    },
  ),
);
```

### 3. 设置路由生成器

在 `MaterialApp` 中设置 `onGenerateRoute`，以便使用 Fluro 的路由生成器。

```dart
void main() {
  runApp(MaterialApp(
    onGenerateRoute: router.generator,
    // 其他配置...
  ));
}
```

---

## 定义路由

`define` 方法用于定义应用程序中的路由。

```dart
void define(
  String routePath, {
  required Handler handler,
  TransitionType? transitionType,
  Duration transitionDuration = const Duration(milliseconds: 250),
  RouteTransitionsBuilder? transitionBuilder,
  bool? opaque,
  List<AuthMiddleware> middleware = const [],
})
```

- **routePath**：路由的路径，例如 `/home`。
- **handler**：当导航到此路由时要执行的处理程序。
- **transitionType**：（可选）指定页面过渡动画的类型。
- **transitionDuration**：（可选）过渡动画的持续时间。
- **transitionBuilder**：（可选）自定义过渡动画的构建器。
- **opaque**：（可选）页面是否不透明。
- **middleware**：（可选）应用于此路由的中间件列表。

### 示例

```dart
router.define(
  "/profile/:userId",
  handler: profileHandler,
  transitionType: TransitionType.cupertino,
  middleware: [authMiddleware],
);
```

---

## 中间件与鉴权

中间件是一些在导航到路由之前执行的函数，可以用于鉴权、日志记录、分析等。通过中间件，您可以控制用户是否有权访问特定的路由。

### 定义中间件

中间件是 `AuthMiddleware` 的实例，需要提供一个 `authGuard` 函数，该函数返回一个 `FutureOr<bool>`，表示是否允许继续导航。

```dart
final authMiddleware = AuthMiddleware(
  authGuard: (BuildContext context, String routeName,
      Map<String, List<String>> parameters) async {
    // 在这里执行鉴权逻辑，例如检查用户是否已登录
    bool isAuthenticated = await checkUserAuthentication();
    return isAuthenticated;
  },
);
```

### 全局中间件

全局中间件会应用于所有路由。使用 `useMiddleware` 方法添加全局中间件。

```dart
router.useMiddleware(authMiddleware);
```

### 路由特定的中间件

您可以在定义路由时，为特定路由添加中间件。

```dart
router.define(
  "/admin",
  handler: adminHandler,
  middleware: [adminMiddleware],
);
```

### 未授权处理程序

未授权处理程序会在用户未通过鉴权时调用，通常用于导航到登录页面或显示错误信息。

```dart
router.notAuthorizedHandler = Handler(
  handlerFunc:
      (BuildContext? context, Map<String, List<String>> parameters) {
    return LoginPage();
  },
);
```

---

## 导航

使用 `navigateTo` 方法导航到指定的路由。

```dart
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
})
```

- **context**：当前的 `BuildContext`。
- **path**：要导航到的路由路径。
- **replace**：是否替换当前路由。
- **clearStack**：是否清空导航堆栈。
- 其他参数与 `define` 方法类似。

### 示例

```dart
router.navigateTo(context, "/profile/123");
```

---

## 示例代码

以下是一个完整的示例，演示如何使用 Fluro 路由库的路由鉴权功能。

### 1. 设置路由器

```dart
final router = FluroRouter();

// 定义未授权处理程序
router.notAuthorizedHandler = Handler(
  handlerFunc:
      (BuildContext? context, Map<String, List<String>> parameters) {
    return LoginPage();
  },
);
```

### 2. 定义中间件

#### 全局鉴权中间件

```dart
final authMiddleware = AuthMiddleware(
  authGuard: (BuildContext context, String routeName,
      Map<String, List<String>> parameters) async {
    // 检查用户是否已登录
    bool isAuthenticated = await checkUserAuthentication();
    return isAuthenticated;
  },
);

// 添加全局中间件
router.useMiddleware(authMiddleware);
```

#### 管理员权限中间件

```dart
final adminMiddleware = AuthMiddleware(
  authGuard: (BuildContext context, String routeName,
      Map<String, List<String>> parameters) async {
    // 检查用户是否具有管理员权限
    bool isAdmin = await checkIfUserIsAdmin();
    return isAdmin;
  },
);
```

### 3. 定义路由

```dart
// 普通用户可以访问的路由
router.define(
  "/home",
  handler: Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
      return HomePage();
    },
  ),
);

// 需要管理员权限的路由
router.define(
  "/admin",
  handler: Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
      return AdminPage();
    },
  ),
  middleware: [adminMiddleware],
);

// 登录页面
router.define(
  "/login",
  handler: Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> parameters) {
      return LoginPage();
    },
  ),
);
```

### 4. 在 `MaterialApp` 中设置路由生成器

```dart
void main() {
  runApp(MaterialApp(
    onGenerateRoute: router.generator,
    // 其他配置...
  ));
}
```

### 5. 导航示例

```dart
// 导航到主页
router.navigateTo(context, "/home");

// 导航到管理员页面
router.navigateTo(context, "/admin");
```

---

## 注意事项

- **异步鉴权**：鉴权函数可以是异步的，支持网络请求或其他异步操作。
- **错误处理**：在中间件中，返回 `false` 即可阻止导航，Fluro 会自动调用未授权处理程序。
- **参数传递**：路由路径中的参数（例如 `/profile/:userId`）会解析为参数，您可以在处理程序中使用 `parameters` 获取。
- **过渡动画**：您可以为路由指定过渡动画类型，或提供自定义的过渡动画构建器。

---

## 结论

通过在 Fluro 路由库中添加中间件和鉴权功能，您可以更灵活地控制应用程序的导航逻辑。中间件机制允许您在导航之前执行任何必要的检查或处理，使您的应用程序更安全和健壮。

希望本使用文档能帮助您充分利用 Fluro 路由库的功能，构建出优秀的 Flutter 应用程序。

---

如果您有任何疑问或需要进一步的帮助，请随时提问。