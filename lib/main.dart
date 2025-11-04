import 'package:flutter/material.dart';
import 'package:frontend/services/notificationService.dart';
import 'package:frontend/pages/Inscription.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Inscription(),
    );
  }
}

class InscriptionWithNotification extends StatelessWidget {
  const InscriptionWithNotification({super.key});

  void _onNotifyPressed() {
    NotificationService.showNotification(
      id: 1,
      title: 'Bienvenue 🎉',
      body: 'Merci pour ton inscription !',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Inscription(),
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton(
            onPressed: _onNotifyPressed,
            child: const Icon(Icons.notifications),
          ),
        ),
      ],
    );
  }
}
