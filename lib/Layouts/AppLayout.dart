import 'package:flutter/material.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Applayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic> data;

  const Applayout({
    super.key,
    required this.currentIndex,
    required this.onTap,
     required this.data, 
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF05445E),
      iconSize: 35.5,
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "historique",
        ),
        //  BottomNavigationBarItem(
        //   icon: Icon(Icons.add_circle, size: 40),
        //   label: "",
        // ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.crown ),
          label: "Abonnements",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Paramètres",
        ),
      ],
    );
  }
}
