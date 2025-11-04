import 'package:flutter/material.dart';
import 'package:frontend/pages/DisbursementPage.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/SettingsPage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const HistoryPage({super.key, required this.data});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int currentIndex = 3;
  int selectedFilterIndex = 1;

  final List<String> filterLabels = ["1 semaine", "1 mois", "4 mois", "6 mois"];
  List<double> chartValues = [20, 30, 25, 40];
  List<String> chartLabels = ['S1', 'S2', 'S3', 'S4'];

  void updateChart(int filterIndex) {
    selectedFilterIndex = filterIndex;
    switch (filterIndex) {
      case 0:
        chartValues = [5, 6, 4, 7, 3, 8, 6];
        chartLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        break;
      case 1:
        chartValues = [20, 30, 25, 40];
        chartLabels = ['S1', 'S2', 'S3', 'S4'];
        break;
      case 2:
        chartValues = [50, 40, 60, 70];
        chartLabels = ['Jan', 'Fév', 'Mars', 'Avr'];
        break;
      case 3:
        chartValues = [45, 50, 48, 60, 55, 65];
        chartLabels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
        break;
    }
  }

  void handleNavTap(int index) {
    setState(() {
      currentIndex = index;

      Widget destination;

      switch (index) {
        case 0:
          destination = HomePage(data: widget.data); // Accueil
          break;
        case 1:
          destination = EventNotePage(data: widget.data);
          break;
        case 2:
          destination = DisbursementPage(data: widget.data); // Paramètres
          break;
        case 3:
          destination = HistoryPage(data: widget.data); // Historique
          break;

        default:
          destination = SettingsPage(data: widget.data); // Paramètres
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    });
  }

  late String userName = 'Utilisateur inconnu';
  late String lastLogin = 'Non défini';
  late double balance = 0.0;

  @override
  void initState() {
    super.initState();
    final dynamic user = widget.data['user'];
    userName = user['name'];
    lastLogin = DateFormat('dd/MM/yyyy à HH:mm')
        .format(DateTime.parse(user['last_login']));
    balance = 19500.0;

    // balance = double.tryParse(user['wallet']?['balance']?.toString() ?? '') ?? 19500.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C405A), Color(0xFF1178B3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(userName,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Icon(Icons.notifications, color: Colors.white)
                      ],
                    ),
                    SizedBox(height: 4),
                    Text("Dernière connexion : ${lastLogin}",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 16),
                    Text("\$19.500",
                        style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFFFDCB58),
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: filterLabels.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String label = entry.value;
                  bool selected = idx == selectedFilterIndex;

                  return OutlinedButton(
                    onPressed: () {
                      setState(() {
                        updateChart(idx);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor:
                          selected ? const Color(0xFF0C405A) : Colors.white,
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF0C405A)
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("\$127,425",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Cette semaine",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("+33%",
                        style: TextStyle(color: Colors.green.shade700)),
                  )
                ],
              ),
              const SizedBox(height: 4),
              const Text("Moyenne de décaisse : \$1,200",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < chartLabels.length) {
                              return Text(chartLabels[index],
                                  style: const TextStyle(fontSize: 10));
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: List.generate(chartValues.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: chartValues[index],
                            width: 20,
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1178B3), Color(0xFF0C405A)],
                            ),
                          )
                        ],
                      );
                    }),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Applayout(
        currentIndex: currentIndex,
        onTap: handleNavTap,
        data: widget.data,
      ),
    );
  }
}
