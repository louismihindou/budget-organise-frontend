import 'package:flutter/material.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:frontend/components/DepositDialog.dart';
import 'package:frontend/components/EmptyState.dart';
import 'package:frontend/components/withdrawalDialog.dart';
import 'package:frontend/pages/DisbursementPage.dart';
import 'package:frontend/pages/SubscriptionPage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:frontend/pages/SettingsPage.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> data;
  const HomePage({super.key, required this.data});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  String filter = "en_cours"; // filtre par défaut

  Map<String, dynamic>? userData;
  String? userName;
  String? lastLogin;
  double? balance;
  double? rate;
  String? walletName;
  bool isUpdating = false;
  List<Map<String, dynamic>> budgets = [];

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

  String formatName(String name, {int maxLength = 15}) {
    final words = name.trim().split(RegExp(r"\s+"));

    if (words.isEmpty) return "";

    // Premier mot complet
    String result = words[0];

    // Initiales des mots suivants
    if (words.length > 1) {
      for (var i = 1; i < words.length; i++) {
        result += " ${words[i][0].toUpperCase()}.";
      }
    }

    if (result.length > maxLength) {
      result =
          result.substring(0, maxLength) + (maxLength < name.length ? "…" : "");
    }

    return result;
  }

  double calculateReturnedAmount({
    required String startDate,
    required String endDate,
    required double totalAmount,
  }) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      if (totalAmount <= 0) return 0.0;
      if (now.isBefore(start)) return 0.0;
      if (!now.isBefore(end)) return totalAmount;

      final isSameDay = start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;

      if (isSameDay) {
        final totalMinutes = end.difference(start).inMinutes;
        if (totalMinutes <= 0) return totalAmount;

        final elapsedMinutes = now.difference(start).inMinutes;
        final rate = (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);

        final result = totalAmount * rate;
        return result.isFinite ? double.parse(result.toStringAsFixed(2)) : 0.0;
      }

      final totalDays = end.difference(start).inDays;
      if (totalDays <= 0) return totalAmount;

      final elapsedDays = now.difference(start).inDays;
      final rate = (elapsedDays / totalDays).clamp(0.0, 1.0);

      final result = totalAmount * rate;
      return result.isFinite ? double.parse(result.toStringAsFixed(2)) : 0.0;
    } catch (e) {
      print('Erreur de calcul : $e');
      return 0.0;
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      isUpdating = true;
    });

    final response = await ApiService().getUserProfile(widget.data['token']);
    if (response != null && mounted) {
      final updatedUser = response['user'];

      setState(() {
        userName = updatedUser?['name'] ?? userName;
        lastLogin = DateFormat('dd/MM/yyyy à HH:mm')
            .format(DateTime.parse(updatedUser?['last_login']));
        final rawAmount = updatedUser?['wallets'][0]['current_amount'];
        balance = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0;
        rate = double.tryParse(
                updatedUser?['percent']?['rate']?.toString() ?? '8.0') ??
            8.0;
        walletName = updatedUser?['wallets']?[0]?['name'];
        userData = updatedUser;
        budgets = List<Map<String, dynamic>>.from(
            updatedUser?['wallets'][0]['budgets'] ?? budgets);
        isUpdating = false;
      });
    } else {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Filtrer les budgets selon le choix de l'utilisateur
    final filteredBudgets = budgets.where((budget) {
      final endDate = DateTime.parse(budget["end_date"]);

      if (filter == "en_cours") {
        return endDate.isAfter(now);
      } else if (filter == "termines") {
        return endDate.isBefore(now);
      } else {
        return true; // tous
      }
    }).toList();

    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Budget Organisé",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 24, 93, 128),
                      Color.fromARGB(185, 17, 120, 179)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(userName ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EventNotePage(data: widget.data),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Dernière connexion : ${lastLogin ?? ''}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10)),
                    const SizedBox(height: 16),
                    Text("${(balance ?? 0.0).toStringAsFixed(0)} XAF",
                        style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFFFDCB58),
                            fontWeight: FontWeight.bold)),
                    if (isUpdating)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Actualisation en cours...",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DepositDialog(widget.data['token']),
                  ).then((_) {
                    _loadUserData();
                  });
                },
                label: const Text(
                  'Dépôt',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C405A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 25),
              ElevatedButton.icon(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  await _loadUserData();

                  if (!mounted) return;
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => WithdrawalDialog(
                      widget.data['token'],
                      rate: rate,
                      walletName: walletName,
                    ),
                  );
                },
                label: const Text('Rétrait', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C405A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(
                      color: Color(0xFF0C405A),
                      width: 1,
                    ),
                  ),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF0C405A), width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove,
                      size: 20, color: Color(0xFF0C405A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ligne Budgets + Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text("Budgets",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 16),
                ],
              ),
              DropdownButton<String>(
                value: filter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "en_cours", child: Text("En cours")),
                  DropdownMenuItem(value: "termines", child: Text("Terminés")),
                  DropdownMenuItem(value: "tous", child: Text("Tous")),
                ],
                onChanged: (value) {
                  setState(() {
                    filter = value!;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        filteredBudgets.isEmpty
            ? const EmptyState(message: "Aucun budget trouvé")
            : SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: filteredBudgets.length,
                  controller: PageController(viewportFraction: 0.85),
                  itemBuilder: (context, index) {
                    final item = filteredBudgets[index];
                    final totalDays = item['totalDays'];
                    final passedDays =
                        double.parse(item['passedDays'].toString());
                    final usedAmount =
                        passedDays * double.parse(item['amount'].toString());
                    final progress =
                        totalDays > 0 ? passedDays / totalDays : 0.0;
                    final destinataire = (item['destinataire'] is List &&
                            item['destinataire'].isNotEmpty)
                        ? item['destinataire'][0]['phone_number']
                        : null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF5692b1), Color(0xFF065F8C)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                  formatName(item["name"].toUpperCase()),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFC107))),
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 2, // ✅ deux colonnes
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 15,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio:
                                  5, // largeur / hauteur (ajuste si besoin)
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                        DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(item["start_date"])),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.event_available,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                        DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(item["end_date"])),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_outlined,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(item["disbursement_time"],
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${double.parse(item['amount'].toString()).toStringAsFixed(0)} XAF",
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ],
                                ),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.handCoins,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: (item['destinataire']
                                                      is List &&
                                                  item['destinataire']
                                                      .isNotEmpty)
                                              ? item['destinataire']
                                                  .map<Widget>((d) => Text(
                                                        d['phone_number'] ??
                                                            "Numéro inconnu",
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors.white),
                                                      ))
                                                  .toList()
                                              : [
                                                  const Text(
                                                    "vous-même",
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white),
                                                  )
                                                ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${item['passedDays']}/${item['totalDays']}",
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${double.parse(item['total_amount'].toString()).toStringAsFixed(0)} XAF",
                                  style: const TextStyle(
                                      color: Color(0xFFFFC107),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "${(progress * 100).toInt()}%",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Stack(
                              children: [
                                Container(
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      height: 25,
                                      width: constraints.maxWidth * progress,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C405A),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  left: 12,
                                  top: 2,
                                  child: Text(
                                    "${usedAmount.toStringAsFixed(0)} XAF",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFB0BEC5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
      ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisbursementPage(data: widget.data),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 221, 224, 221),
        foregroundColor: const Color(0xFF05445E),
        tooltip: 'Ajouter',
        child: const Icon(Icons.add_circle, size: 55),
      ),
      bottomNavigationBar: Applayout(
        currentIndex: currentIndex,
        onTap: handleNavTap,
        data: widget.data,
      ),
    );
  }
}
