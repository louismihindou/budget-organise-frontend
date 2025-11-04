import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:frontend/components/EmptyState.dart';
import 'package:frontend/pages/SubscriptionPage.dart';
import 'package:frontend/pages/DisbursementPage.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/SettingsPage.dart';
import 'package:frontend/services/api_service.dart';

class EventNotePage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EventNotePage({super.key, required this.data});

  @override
  State<EventNotePage> createState() => _EventNotePageState();
}

class _EventNotePageState extends State<EventNotePage> {
  int currentIndex = 1;
  String selectedType =
      'Tous'; // Valeurs possibles : Tous, recharge, retrait, decaissement

  DateTime? startDate;
  DateTime? endDate;

  void handleNavTap(int index) {
    setState(() {
      currentIndex = index;
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
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    });
  }

  void _loadUserData() async {
    final response = await ApiService().getUserProfile(widget.data['token']);
    if (response != null && mounted) {
      final updatedUser = response['user'];
      setState(() {
        widget.data['user'] = updatedUser;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  List<Widget> buildGroupedTransactionList(
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>>? budgets,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    // Fusionner transactions
    for (var tx in transactions) {
      String date = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx["date"]));
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(tx);
    }

    // Fusionner budgets
    for (var budget in budgets!) {
      String date =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(budget["start_date"]));
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add({
        "type": "budget",
        "name": budget["name"],
        "montant": budget["amount"],
        "totalDays": budget["totalDays"],
        "TTC": budget["total_amount"],
        "start": DateFormat('yyyy-MM-dd').format(DateTime.parse(budget["start_date"])),
        "end": DateFormat('yyyy-MM-dd').format(DateTime.parse(budget["end_date"])),
        "progress": (budget["passedDays"] /
            (budget["totalDays"] == 0 ? 1 : budget["totalDays"])),
        "remainingDays": budget["remainingDays"],
      });
    }

    // Trier les dates du plus récent au plus ancien
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    List<Widget> widgets = [];

    for (var date in sortedDates) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          "📅 $date",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ));

      for (var tx in grouped[date]!) {
        if (tx["type"] == "decaissement") {
          widgets.add(DecaissementCard(tx: tx));
        } else if (tx["type"] == "budget") {
          widgets.add(BudgetCard(tx: tx));
        } else {
          widgets.add(InfoCard(
            message: tx["type"],
            montant: tx["montant"],
            date: tx['date'],
            color: tx["type"] == "recharge" ? Colors.green : Colors.red,
          ));
        }
      }
    }

    return widgets;
  }

  List<Map<String, dynamic>> getTransactions() {
    final user = widget.data['user'];
    if (user == null) return [];

    final wallets = user['wallets'] ?? [];
    List<Map<String, dynamic>> txList = [];

    for (var wallet in wallets) {
      for (var tx in wallet['transactions'] ?? []) {
        String type = tx['type'];
        double montant = double.tryParse(tx['amount'].toString()) ?? 0.0;
        String label = tx['label'] ?? 'Transaction';
        String? message = tx['message'];
        String dateStr = tx['created_at'] ?? '';
        DateTime? txDate;
        try {
          txDate = DateTime.parse(dateStr);
        } catch (_) {}

        // Filtrer par date si les filtres sont actifs
        if (txDate != null) {
          if (startDate != null && txDate.isBefore(startDate!)) continue;
          if (endDate != null && txDate.isAfter(endDate!)) continue;
        }
        if (selectedType != 'Tous' && tx['type'] != selectedType) {
          continue; // Ignorer les types non sélectionnés
        }

        if (type == 'decaissement' || type == 'budget') {
          txList.add({
            "type": type,
            "label": label,
            "montant": montant,
            "date": tx['created_at'],
            "parJour": tx['par_jour'] ?? '',
            "progress": tx['progress'] ?? 0.0,
          });
        } else if (type == 'recharge' || type == 'retrait') {
          txList.add({
            "type": type,
            "message": message ?? '',
            "montant": montant,
            "date": tx['created_at'],
          });
        }
      }
    }

    // Trier du plus récent au plus ancien
    txList.sort((a, b) {
      final da = DateTime.tryParse(a["date"] ?? "") ?? DateTime(1970);
      final db = DateTime.tryParse(b["date"] ?? "") ?? DateTime(1970);
      return db.compareTo(da);
    });

    return txList;
  }

  List<Map<String, dynamic>> getBudgets() {
    final user = widget.data['user'];
    if (user == null) return [];

    final wallets = user['wallets'] ?? [];
    List<Map<String, dynamic>> budgetsList = [];

    for (var wallet in wallets) {
      for (var budget in wallet['budgets'] ?? []) {
        final double totalAmount =
            double.tryParse(budget['total_amount']?.toString() ?? '0') ?? 0.0;
        final double amount =
            double.tryParse(budget['amount']?.toString() ?? '0') ?? 0.0;
        final String name = budget['name'] ?? ' ';
        final String startDateStr = budget['start_date'] ?? '';
        final String endDateStr = budget['end_date'] ?? '';

        DateTime? startDate;
        try {
          startDate = DateTime.parse(startDateStr);
        } catch (_) {}

        budgetsList.add({
          "id": budget['id'],
          "wallet_id": budget['wallet_id'],
          "name": name,
          "total_amount": totalAmount,
          "amount": amount,
          "disbursement_time": budget['disbursement_time'],
          "start_date": startDateStr,
          "end_date": endDateStr,
          "nombre_depots": budget['nombre_depots'] ?? 0,
          "dernier_depot": budget['dernier_depot'] ?? 0,
          "totalDays": budget['totalDays'] ?? 0,
          "passedDays": budget['passedDays'] ?? 0,
          "remainingDays": budget['remainingDays'] ?? 0,
          // ✅ Calcul du progrès basé sur jours ou montants
          "progress":
              totalAmount > 0 ? (amount / totalAmount).clamp(0.0, 1.0) : 0.0,
          "startDateParsed": startDate,
        });
      }
    }

    // Trier par date de début (du plus récent au plus ancien)
    budgetsList.sort((a, b) {
      final da = a["startDateParsed"] ?? DateTime(1970);
      final db = b["startDateParsed"] ?? DateTime(1970);
      return db.compareTo(da);
    });

    return budgetsList;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial =
        isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = getTransactions();
    final List<Map<String, dynamic>> budgets = getBudgets();
    final dateFormatter = DateFormat('yyyy-MM-dd');
  
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Organisé',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(data: widget.data),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 50, 126, 164),
                  Color.fromARGB(255, 84, 163, 209)
                ],
              ),
              // borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 0.0),
                          borderRadius: BorderRadius.circular(10),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          items: [
                            'Tous',
                            'recharge',
                            'retrait',
                            'decaissement',
                            'budget'
                          ]
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(
                                          type == 'recharge'
                                              ? Icons.arrow_downward
                                              : type == 'retrait'
                                                  ? Icons.arrow_upward
                                                  : type == 'decaissement'
                                                      ? Icons.outbox
                                                      : type == 'budget'
                                                          ? Icons
                                                              .account_balance_wallet_rounded
                                                          : Icons.all_inclusive,
                                          size: 16,
                                          color: Colors.blueGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          type[0].toUpperCase() +
                                              type.substring(1),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate != null
                              ? "Du: ${dateFormatter.format(startDate!)}"
                              : "Début",
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(226, 249, 249, 249),
                          foregroundColor: const Color(0xFF05445E),
                        ),
                        onPressed: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          endDate != null
                              ? "Au: ${dateFormatter.format(endDate!)}"
                              : "Fin",
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(226, 249, 249, 249),
                          foregroundColor: const Color(0xFF05445E),
                        ),
                        onPressed: () => _selectDate(context, false),
                      ),
                    ),
                    Tooltip(
                      message: "Réinitialiser les dates",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedType = 'Tous';
                            startDate = null;
                            endDate = null;
                          });
                        },
                        child: const Icon(Icons.clear),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const EmptyState(
                    message: "Votre historique est vide pour le moment",
                  )
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: buildGroupedTransactionList(transactions,budgets),
                  ),
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

class DecaissementCard extends StatelessWidget {
  final Map<String, dynamic> tx;

  const DecaissementCard({super.key, required this.tx});
  String formatBudgetName(String name, {int maxLength = 15}) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    String result = words[0];
    if (words.length > 1) {
      for (var i = 1; i < words.length; i++) {
        result += ' ${words[i][0].toUpperCase()}.';
      }
    }
    if (result.length > maxLength) {
      result = result.substring(0, maxLength) + '…';
    }
    return result;
  }
   

  @override
  Widget build(BuildContext context) {
    final String autoName = formatBudgetName(tx["label"] ?? "decaissement");
    return Card(
      color: Colors.blue[100],
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title:
            Text('$autoName - ${tx["montant"].toStringAsFixed(0)} Fcfa'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx["date"]),
            Text('${tx["parJour"]}'),
          ],
        ),
        trailing: CircularProgressIndicator(
          value: tx["progress"],
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final Map<String, dynamic> tx;

  const BudgetCard({super.key, required this.tx});

  // Fonction pour afficher le nom comme "Budget A. M."
  String formatBudgetName(String name, {int maxLength = 15}) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    String result = words[0];
    if (words.length > 1) {
      for (var i = 1; i < words.length; i++) {
        result += ' ${words[i][0].toUpperCase()}.';
      }
    }
    if (result.length > maxLength) {
      result = result.substring(0, maxLength) + '…';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final budget = tx["budget"] ?? {};
    final String budgetName =
        formatBudgetName(tx["name"] ?? "Budget");

    final double progress = tx["progress"] != null
        ? (tx["progress"] as num).toDouble().clamp(0.0, 1.0)
        : 0.0;

    final double montantTotal = tx["TTC"] != null
        ? double.tryParse(tx["TTC"].toString()) ?? 0.0
        : 0.0;

    return Card(
      color: Colors.blue[100],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          '$budgetName - ${montantTotal.toStringAsFixed(0)} Fcfa',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${tx['start'] ?? ''} à ${tx['end'] ?? ''}",
              style: const TextStyle(fontSize: 12),textAlign: TextAlign.right ,
            ),
            const SizedBox(height: 4),
            Text(
              '${tx["montant"] ?? 0} X ${tx["totalDays"] ?? 0} jours',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.blueAccent,
              backgroundColor: Colors.blue[200],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}% effectué",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "${(montantTotal * progress).toStringAsFixed(0)} Fcfa reçus",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String message;
  final double montant;
  final String date; // tu reçois une chaîne
  final Color color;

  const InfoCard({
    required this.message,
    required this.montant,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hourFormatter = DateFormat('HH:mm'); // format heure
    // Conversion String → DateTime
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (e) {
      parsedDate = null; // si la conversion échoue
    }

    return Card(
      color: color,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          message.toUpperCase(),
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          parsedDate != null
              ? hourFormatter.format(parsedDate)
              : "--:--", // évite le crash si parsing échoue
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          "$montant Fcfa",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

