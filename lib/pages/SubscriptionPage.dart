import 'package:flutter/material.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:frontend/components/SubscriptionCard.dart';
import 'package:frontend/pages/DisbursementPage.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/SettingsPage.dart';
import 'package:frontend/services/api_service.dart';

class SubscriptionPage extends StatefulWidget {
  final dynamic data;

  const SubscriptionPage({super.key, required this.data});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? activePlan;
  bool _isLoading = false;
  int currentIndex = 2;
  List<Map<String, dynamic>> _subscriptions = [];
  Map<String, dynamic>? activeSubscriptionData;

  void handleNavTap(int index) {
    setState(() => currentIndex = index);
    Widget destination;
    switch (index) {
      case 0:
        destination = HomePage(data: widget.data);
        break;
      case 1:
        destination = EventNotePage(data: widget.data);
        break;
      case 2:
        destination = SubscriptionPage(data: widget.data);
        break;
      case 3:
        destination = SettingsPage(data: widget.data);
        break;
      default:
        destination = DisbursementPage(data: widget.data);
        break;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> _subscribe(Map<String, dynamic> plan,
      {required bool isPremium}) async {
    // Vérifier si un abonnement est déjà actif
    if (activeSubscriptionData != null &&
        activeSubscriptionData!['status'] == 'active') {
      _showAlreadyActiveDialog();
      return;
    }

    final String planKey =
        isPremium ? plan['premium']['key'] : plan['standard']['key'];

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().subscribeToPlan(
        widget.data['token'],
        planKey,
      );

      setState(() {
        activePlan = planKey;
        _isLoading = false;
      });

      _showConfirmationDialog(
        response['message'] ?? "Paiement initié avec succès !",
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> _loadPlansData() async {
    try {
      final List<dynamic> plans = widget.data['plans'];
      final List<dynamic> abonnement = widget.data['user']['subscript'] ?? [];

// 🔹 récupère le premier abonnement actif et cast en Map<String, dynamic>
      if (abonnement.isNotEmpty) {
        activeSubscriptionData = Map<String, dynamic>.from(
          abonnement.firstWhere(
            (s) => s['status'] == 'active',
            orElse: () => abonnement.first,
          ),
        );
      }

      // Regrouper les plans par période (weekly, monthly, etc.)
      Map<String, Map<String, dynamic>> groupedPlans = {};

      for (var plan in plans) {
        final key = plan['key'] as String;
        final duration = plan['duration'] as int;
        final price = double.tryParse(plan['price'].toString()) ?? 0.0;
        final rate = double.tryParse(plan['rate'].toString()) ?? 0.0;

        final periodKey = key.split('_')[0];
        final type = key.split('_')[1]; // standard ou premium

        groupedPlans.putIfAbsent(
            periodKey,
            () => {
                  'period': 'Abonnement ${_getLabel(periodKey)}',
                  'duration': '$duration jours',
                  'standard': {},
                  'premium': {},
                });

        groupedPlans[periodKey]![type] = {
          'key': key,
          'price': price,
          'discount': rate,
        };
      }

      final List<Map<String, dynamic>> subscriptions =
          groupedPlans.values.toList();

      setState(() {
        _subscriptions = subscriptions;
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des plans : $e");
    }
  }

  String _getLabel(String key) {
    switch (key) {
      case 'weekly':
        return 'hebdomadaire';
      case 'monthly':
        return 'mensuel';
      case 'quarterly':
        return 'trimestriel';
      case 'halfyearly':
        return 'semestriel';
      case 'yearly':
        return 'annuel';
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlansData();
    _prepareActiveSubscription();
  }

  void _showConfirmationDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAlreadyActiveDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Abonnement actif"),
        content: const Text("Vous avez déjà un abonnement actif."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _prepareActiveSubscription() {
    final List<dynamic> subscriptions = widget.data['user']['subscript'] ?? [];

    if (subscriptions.isEmpty) {
      activeSubscriptionData = null;
      return;
    }

    // 🔹 Cherche l'abonnement actif
    final active = subscriptions.firstWhere(
      (s) => s['status'] == 'active',
      orElse: () => null,
    );

    if (active != null) {
      activeSubscriptionData = Map<String, dynamic>.from(active);
    } else {
      // 🔹 Sinon, récupère le plus récent expiré (end_date le plus récent)
      subscriptions.sort((a, b) {
        final endA = DateTime.tryParse(a['end_date'] ?? '') ?? DateTime(1970);
        final endB = DateTime.tryParse(b['end_date'] ?? '') ?? DateTime(1970);
        return endB.compareTo(endA); // décroissant
      });
      activeSubscriptionData = Map<String, dynamic>.from(subscriptions.first);
    }
  }

  /// 🔹 Widget pour l’abonnement actif
  Widget _buildActiveSubscriptionCard(
      Map<String, dynamic>? activeSubscription) {
    if (activeSubscription == null) {
      return const SizedBox.shrink();
    }
    // 🔹 Lecture correcte du plan
    final Map<String, dynamic>? plan = activeSubscription['plan'];
    final String planName = plan?['label'] ?? 'Plan inconnu';

    // 🔹 Lecture correcte de la date
    final String? endDateStr = activeSubscription['end_date'];
    final DateTime? endDate =
        endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    final int daysLeft =
        endDate != null ? endDate.difference(DateTime.now()).inDays : 0;
    final String status = activeSubscription['status'] ?? 'inconnu';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF185D80), Color(0xFF1178B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mon abonnement actuel",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            planName,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Statut : ${status.toUpperCase()}",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            endDate != null
                ? "Expire le : ${endDate.toLocal().toString().split(' ')[0]}"
                : "Date de fin inconnue",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Jours restants : $daysLeft",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Mes abonnements"), centerTitle: true),
    body: _subscriptions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildActiveSubscriptionCard(activeSubscriptionData),
                  ..._subscriptions.map((plan) {
                    return SubscriptionCard(
                      periodLabel: plan['period'],
                      duration: plan['duration'],
                      standardPlan: plan['standard'],
                      premiumPlan: plan['premium'],
                      activePlan: activePlan,
                      onStandardPressed: () => _subscribe(plan, isPremium: false),
                      onPremiumPressed: () => _subscribe(plan, isPremium: true),
                    );
                  }).toList(),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
    bottomNavigationBar: Applayout(
      currentIndex: currentIndex,
      onTap: handleNavTap,
      data: widget.data,
    ),
  );
}
}
