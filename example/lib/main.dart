import 'package:conditional_trigger/conditional_trigger.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bannerSurvey = const ConditionalTrigger('BannerSurvey');
  final announce = const ConditionalTrigger('Announce');

  @override
  void initState() {
    super.initState();
  }

  void initial() async {
    if (await announce.checkOnce() == ConditionalState.satisfied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Announce'),
            content: Text('This is an announcement'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: FutureBuilder(
            future: bannerSurvey.checkOnce(),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.fromSize();
              }

              return const Text('This is a survey banner');
            }),
      ),
    );
  }
}
