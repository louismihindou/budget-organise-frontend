import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final double imageHeight;

  const EmptyState({
    Key? key,
    required this.message,
    this.imageHeight = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Remplacer l'image par un Asset si tu veux l'intégrer localement
          Image.asset(
            'assets/images/empty.png',
            height: imageHeight,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
