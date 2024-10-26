import 'package:fluro_example/demo1/routes.dart';
import 'package:flutter/material.dart';

import 'application.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo 1',
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
            onTap: () {
              print("click $index");
              Application.router.navigateTo(context, Routes.details,
                  routeSettings: RouteSettings(arguments: {"id": index}));
            },
          );
        },
      ),
    );
  }
}
