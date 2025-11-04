import 'package:flutter/material.dart';

class PolitiqueScreen extends StatelessWidget {
  const PolitiqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Politique Générale"),
        backgroundColor: const Color(0xFF05445E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '''
          Politique Générale de l'Application
                   "Budget Organisé"

                  1. Introduction
L'application "Budget Organisé" vous aide à gérer vos finances via un portefeuille numérique (B.O).

                  2. Objectifs
- Gestion des finances planifiées
- Éducation financière
- Planification budgétaire

                  3. Sécurité
Données cryptées et stockées de façon sécurisée.

                  4. Confidentialité
Aucune donnée partagée sans votre accord.

                  5. Utilisation
- Application gratuite
- Création de compte requise
- Tableaux de bord, alertes, rapports

                  6. Souscription
Accepter les conditions avant toute utilisation.

                  7. Assistance
Disponible via l'app ou notre site.

                  8. Mises à jour
Modifications possibles avec notification.

                  9. Conclusion
Nous vous accompagnons dans votre gestion financière.
            ''',
            style: const TextStyle(fontSize: 14,color: Color(0xFF05445E)),
          ),
        ),
      ),
    );
  }
}
