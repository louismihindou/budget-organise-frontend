import 'package:flutter/material.dart';
import 'package:frontend/pages/HomePage.dart';

class SuccessScreen extends StatelessWidget {
  final dynamic data;

  const SuccessScreen({super.key,required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF064663), // Bleu foncé
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎆 Image décorative du feu d’artifice
                Image.asset(
                  'assets/images/fireworks.png',
                  height: 200,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Félicitations ! 🎉',
                  style: TextStyle(
                    color: Color(0xFFF4D35E),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre compte est créé avec succès.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenue dans B.O, votre gestionnaire de portefeuille\nélectronique sécurisé et pratique ! 🚀',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage( data: data),
                      ),
                    );
                    ;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF189AB4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Aller à l'accueil",
                    style: TextStyle(fontSize: 16,color: Color(0xFFFFFFFF)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
