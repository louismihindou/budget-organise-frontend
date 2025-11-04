import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final String periodLabel; // Ex: "Hebdomadaire"
  final String duration;
  final Map<String, dynamic> standardPlan;
  final Map<String, dynamic> premiumPlan;
  final String? activePlan;
  final VoidCallback onStandardPressed;
  final VoidCallback onPremiumPressed;

  const SubscriptionCard({
    Key? key,
    required this.periodLabel,
    required this.duration,
    required this.standardPlan,
    required this.premiumPlan,
    required this.activePlan,
    required this.onStandardPressed,
    required this.onPremiumPressed,
  }) : super(key: key);

  Widget buildPlanCard(
    BuildContext context,
    String title,
    Map<String, dynamic> plan,
    bool isActive,
    VoidCallback onPressed, {
    bool isPremium = false,
  }) {
    final bool isPremiumCard = isPremium;

    return Container(
      height: 200, // 🔹 même hauteur pour toutes les cartes
      decoration: BoxDecoration(
        gradient: isPremiumCard
            ? const LinearGradient(
                colors: [
                  Color.fromARGB(255, 24, 93, 128),
                  Color.fromARGB(185, 17, 120, 179),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPremiumCard
            ? null
            : (isActive ? Colors.green.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:isPremiumCard ? Colors.transparent : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isPremiumCard ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,fontSize: 17
                ),
          ),
          Text(
            "${plan['price'].toInt()} fcfa",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isPremiumCard ? Colors.white : Colors.black,
            ),
          ),
          Text(
            "Taux réduit : ${plan['discount']}%",
            style: TextStyle(
              color: isPremiumCard ? Colors.white70 : Colors.grey[700],fontSize: 10,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.payment),
            label: Text("S'abonner"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremiumCard ? Colors.white :  Color.fromARGB(255, 24, 93, 128),
              foregroundColor:
                  isPremiumCard ?  Color.fromARGB(255, 24, 93, 128) : Colors.white,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                periodLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                "Durée : $duration",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: buildPlanCard(
                    context,
                    "Standard",
                    standardPlan,
                    activePlan == standardPlan['key'],
                    onStandardPressed,
                    isPremium: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildPlanCard(
                    context,
                    "Premium",
                    premiumPlan,
                    activePlan == premiumPlan['key'],
                    onPremiumPressed,
                    isPremium: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
