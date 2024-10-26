
import 'package:fluro_example/demo1/application.dart';
import 'package:fluro_pro/fluro.dart';
import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
      ),
      body: Center(
        child: Text(context.arguments.toString()),
      )
    );
  }
}
