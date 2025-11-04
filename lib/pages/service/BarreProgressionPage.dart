import 'package:flutter/material.dart';

class BarreProgressionPage extends StatefulWidget {
  const BarreProgressionPage({super.key});

  @override
  State<BarreProgressionPage> createState() => _BarreProgressionPageState();
}

class _BarreProgressionPageState extends State<BarreProgressionPage> {
  double progress = 0.3; // 30% de progression initiale

  void augmenterProgression() {
    setState(() {
      if (progress < 1.0) {
        progress += 0.1;
      }
    });
  }

  void reduireProgression() {
    setState(() {
      if (progress > 0.0) {
        progress -= 0.1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barre de progression")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Progression actuelle :", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress, // entre 0.0 et 1.0
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: reduireProgression,
                  child: const Text("Réduire"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: augmenterProgression,
                  child: const Text("Augmenter"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
