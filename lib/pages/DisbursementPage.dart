import 'package:flutter/material.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/pages/SubscriptionPage.dart';
import 'package:frontend/components/DepositDialog.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/SettingsPage.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class DisbursementPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DisbursementPage({super.key, required this.data});

  @override
  _DisbursementPageState createState() => _DisbursementPageState();
}

class _DisbursementPageState extends State<DisbursementPage> {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  int currentIndex = 0;
  final apiService = ApiService();
  double? balance;
  String? walletName;
  double? rate;
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  Set<int> selectedDays = {};
  List<DateTime> exceptions = [];
  TimeOfDay? disbursementTime = TimeOfDay(hour: 7, minute: 30);
  double? totalAmount;
  bool isLoading = false;
  bool otherNumber = false;
  bool applyWithdrawalFee = false;
  bool hasActiveSubscription = false;
  List<Map<String, dynamic>> recipients = [];

  String disbursementMode = "multi_days"; // valeurs: "one_day" ou "multi_days"

  final List<String> daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];
  Future<void> refreshUserData() async {
    final response = await ApiService().getUserProfile(widget.data['token']);
    if (response != null) {
      setState(() {
        final updatedUser = response['user'];
        final rawAmount = updatedUser?['wallets']?[0]?['current_amount'];
        walletName = updatedUser?['wallets']?[0]?['name'];
        final rateApp = updatedUser?['percent']?['rate'] ?? 8;
        balance = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0;
        rate = rateApp is num
            ? rateApp.toDouble()
            : double.tryParse(rateApp?.toString() ?? '8') ?? 8.0;
      });
    }
  }

  void handleNavTap(int index) {
    if (index == currentIndex) return; // Si même page, ne rien faire

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
            child: Text(
          "ATTENTION",
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        )),
        content: const Text(
            "Vous avez des informations non enregistrées. Si vous quittez cette page, elles seront perdues.\n\nVoulez-vous vraiment continuer ?"),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.pop(context), // Reste sur la page
          //   child: const Text("Annuler"),
          // ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ferme le popup
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
                case 4:
                  destination = DisbursementPage(data: widget.data);
                  break;
                default:
                  destination = DisbursementPage(data: widget.data);
                  break;
              }
              // Navigue vers la page choisie
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            },
            child:  
            const Text(
              "Quitter",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void updateTotalAmount() {
    setState(() {
      totalAmount = calculateTotalAmount();
    });
  }

bool isValidRecipient(String phone, String walletType) {
  const airtelPrefixes = ['077', '074', '076'];
  const mobicashPrefixes = ['062', '065', '066'];

  // Normalisation du numéro
  var normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (normalized.startsWith('+241')) normalized = '0${normalized.substring(4)}'; // garder le 0
  if (!normalized.startsWith('0')) normalized = '0$normalized'; // s'assurer qu'il commence par 0

  if (walletType == "AIRTEL_MONEY") {
    return airtelPrefixes.any((prefix) => normalized.startsWith(prefix));
  } else if (walletType == "MOOV_MONEY") {
    return mobicashPrefixes.any((prefix) => normalized.startsWith(prefix));
  }
  return false;
}


  void handleInsufficientFunds(double walletBalance) {
    final parsedAmount = totalAmount ?? 0.0;

    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Montant invalide")),
      );
      return;
    }

    double fee = 0;
    if (applyWithdrawalFee) {
      fee =
          parsedAmount >= 160000 ? 5000 : (parsedAmount * 0.03).ceilToDouble();
    }

    final amountWithFee = parsedAmount + fee;
    final missingAmount = amountWithFee - walletBalance;

    if (missingAmount > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Fonds insuffisants"),
          content: Text(
            "Vous devez déposer au moins ${missingAmount.toStringAsFixed(0)} F pour effectuer cette opération.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepositDialog(
                      widget.data['token'],
                      initialAmount:
                          missingAmount, // Assure-toi d'ajouter ce champ dans DepositDialog
                    ),
                  ),
                );
              },
              child: const Text("Faire un dépôt"),
            ),
          ],
        ),
      );
    }
  }

  Map<String, dynamic> buildDisbursementPayload() {
    // If multi-recipient, build recipients payload (format 1)
    if (recipients.isNotEmpty) {
      final recips = recipients
          .map((r) => {
                "phone": r['phone']!.text.trim(),
                "amount": double.tryParse(r['amount']!
                        .text
                        .replaceAll(' ', '')
                        .replaceAll(',', '.')) ??
                    0.0
              })
          .toList();

      return {
        "label": labelController.text.trim(),
        "recipients": recips,
        "days": selectedDays.toList(),
        "total_amount": totalAmount,
        "start_date": startDate.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
        "disbursement_time": disbursementTime != null
            ? "${disbursementTime!.hour.toString().padLeft(2, '0')}:${disbursementTime!.minute.toString().padLeft(2, '0')}"
            : null,
        "exceptions": exceptions.map((e) => e.toIso8601String()).toList(),
      };
    }

    // Single amount mode (no recipients)
    final rawAmount =
        amountController.text.replaceAll(' ', '').replaceAll(',', '.');
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    double amountWithFee = parsedAmount;

    if (applyWithdrawalFee) {
      final fee =
          parsedAmount >= 160000 ? 5000 : (parsedAmount * 0.03).roundToDouble();
      amountWithFee += fee;
    }

    return {
      "label": labelController.text.trim(),
      "amount": amountWithFee, // Montant avec frais
      "phone": phoneController.text.trim(),
      "days": selectedDays.toList(),
      "total_amount": totalAmount,
      "start_date": startDate.toIso8601String(),
      "end_date": endDate?.toIso8601String(),
      "disbursement_time": disbursementTime != null
          ? "${disbursementTime!.hour.toString().padLeft(2, '0')}:${disbursementTime!.minute.toString().padLeft(2, '0')}"
          : null,
      "exceptions": exceptions.map((e) => e.toIso8601String()).toList(),
    };
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (disbursementMode == "one_day" &&
          DateUtils.isSameDay(startDate, DateTime.now())) {
        final now = DateTime.now().add(const Duration(minutes: 5));
        final selectedDateTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          picked.hour,
          picked.minute,
        );

        if (selectedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "L'heure depôt doit être d'au moins +5min l'heure actuelle")),
          );
          return;
        }
      }

      setState(() => disbursementTime = picked);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;

        if (disbursementMode == "one_day") {
          selectedDays = {picked.weekday};
          endDate = picked;
        } else {
          if (endDate != null && endDate!.isBefore(picked)) endDate = null;
        }

        updateTotalAmount();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        updateTotalAmount();
      });
    }
  }

  Future<void> _selectExceptionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().isBefore(startDate) ? startDate : DateTime.now(),
      firstDate: startDate,
      lastDate: endDate ?? DateTime(2100),
    );
    if (picked != null && !exceptions.contains(picked)) {
      setState(() {
        exceptions.add(picked);
        updateTotalAmount();
      });
    }
  }

  List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    List<DateTime> days = [];
    DateTime current = start;
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  bool validateSelectedDaysInRange({
    required DateTime start,
    required DateTime end,
    required Set<int> selectedDays,
  }) {
    Set<int> daysInRange = {};
    for (DateTime d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      daysInRange.add(d.weekday);
    }
    for (int day in selectedDays) {
      if (!daysInRange.contains(day)) {
        return false;
      }
    }
    return true;
  }

  double calculateTotalAmount() {
    if (endDate == null) return 0.0;

    final daysInRange = getDaysInRange(startDate, endDate!);
    final validDays = daysInRange
        .where((d) =>
            selectedDays.contains(d.weekday) &&
            !exceptions.any((e) =>
                e.year == d.year && e.month == d.month && e.day == d.day))
        .toList();

    double total = 0.0;
    final rateApp = (rate != null ? rate! / 100 : 0.08);

    if (recipients.isEmpty) {
      // Montant global si pas de destinataires
      double amount =
          double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (applyWithdrawalFee) {
        amount = amount >= 160000 ? amount + 5000 : amount * 1.03;
      }
      total = amount * validDays.length;
    } else {
      // Calcul pour chaque destinataire
      for (var r in recipients) {
        double amount =
            double.tryParse(r['amount']!.text.replaceAll(',', '.')) ?? 0.0;
        if (applyWithdrawalFee) {
          amount = amount >= 160000 ? amount + 5000 : amount * 1.03;
        }
        total += amount * validDays.length;
      }
    }

    total = total / (1 - rateApp);
    return total.ceilToDouble();
  }

  String getWithdrawalFeeText() {
    if (recipients.isEmpty) {
      final rawText =
          amountController.text.replaceAll(' ', '').replaceAll(',', '.');
      if (rawText.isEmpty) return '';
      final amount = double.tryParse(rawText);
      if (amount == null) return '';
      final fee = amount >= 160000 ? 5000 : (amount * 0.03).round();
      return "$fee XAF sera ajouté comme frais de retrait";
    } else {
      List<String> fees = [];
      for (int i = 0; i < recipients.length; i++) {
        final rawText = recipients[i]['amount']!
            .text
            .replaceAll(' ', '')
            .replaceAll(',', '.');
        final amount = double.tryParse(rawText) ?? 0.0;
        final fee = amount >= 160000 ? 5000 : (amount * 0.03).round();
        fees.add("Destinataire ${i + 1} : $fee XAF");
      }
      return "Frais de retrait par destinataire:\n${fees.join('\n')}";
    }
  }

  bool _validateInput() {
    if (recipients.isEmpty) {
      final text = amountController.text;
      var value = double.tryParse(text);

      if (value == null && text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entrez un montant valide svp")),
        );
        return false;
      }
      if (value == null || value <= 200 || value >= 500000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entrez un montant compris entre 200 et 500 000 svp"),
          ),
        );
        return false;
      }
    } else {
      // Validate each recipient
      for (int i = 0; i < recipients.length; i++) {
        final phone = recipients[i]['phone']!.text.trim();
        final rawAmount = recipients[i]['amount']!
            .text
            .replaceAll(' ', '')
            .replaceAll(',', '.');
        final amt = double.tryParse(rawAmount);

        if (phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Téléphone du destinataire ${i + 1} manquant")),
          );
          return false;
        }
        if (amt == null || amt <= 200 || amt >= 500000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Montant du destinataire ${i + 1} invalide (200 - 500000)")),
          );
          return false;
        }
        if (!isValidRecipient(phone, walletName!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Le destinataire ${i + 1} doit utiliser le même service mobile que vous")),
          );
          return false;
        }
      }
    }
    return true;
  }

  String formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : ' ';
  }

  Future<void> handleSubmit() async {
    if (labelController.text.isNotEmpty && selectedDays.isNotEmpty) {
      if (endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Veuillez sélectionner une date de fin")),
        );
        return;
      }

      bool isValid = validateSelectedDaysInRange(
        start: startDate,
        end: endDate!,
        selectedDays: selectedDays,
      );

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Les jours sélectionnés ne sont pas dans la période"),
          ),
        );
        return;
      }

      // Validate amounts & phones
      if (!_validateInput()) {
        return; // On stoppe si erreur
      }

      setState(() => isLoading = true);

      updateTotalAmount(); // ensure total is up-to-date
      final payload = buildDisbursementPayload();
      final response = await apiService.sendDisbursementToAPI(
        context,
        payload,
        widget.data['token'],
        balance ?? 0.0,
      );

      setState(() => isLoading = false);

      if (response.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${response.message}")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(data: widget.data)),
        );
      } else {
        if (response.code == 400) {
          handleInsufficientFunds(balance ?? 0.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${response.message}")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Veuillez remplir tous les champs requis correctement")),
      );
    }
  }

  bool get hasSubscription {
    final subs = widget.data['user']?['subscript'];
    if (subs != null && subs.isNotEmpty) {
      return subs[0]['status'] == "active";
    }
    return false;
  }

  @override
  @override
  void initState() {
    super.initState();

    // Vérifier abonnement actif
    final subscriptions = widget.data['user']?['subscript'] ?? [];
    hasActiveSubscription =
        subscriptions.any((sub) => sub['status'] == 'active');

    // Sécurité : vérifier que data est présent
    if (widget.data == null || widget.data['user'] == null) {
      balance = 0.0;
      rate = 8.0; // valeur par défaut
    } else {
      final wallets = widget.data['user']?['wallets'];
      final rawAmount = (wallets != null && wallets.isNotEmpty)
          ? wallets[0]['current_amount']
          : 0.0;

      final rateApp = widget.data['user']?['percent']?['rate'] ?? 8.0;

      balance = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '0.0') ?? 0.0;

      rate = rateApp is num
          ? rateApp.toDouble()
          : double.tryParse(rateApp?.toString() ?? '8') ?? 8.0;
    }

    amountController.addListener(updateTotalAmount);
    // amountController.addListener(_validateInput);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshUserData();
      updateTotalAmount();
    });
  }

  @override
  void dispose() {
    amountController.removeListener(updateTotalAmount);
    amountController.dispose();
    labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text("Nouveau décaissement",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF05445E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomInputField(
                          hintText: "Libellé du décaissement ",
                          controller: labelController),
                      if (recipients.length < 1)
                        CustomInputField(
                            hintText: "Montant (XAF)",
                            controller: amountController,
                            keyboardType: TextInputType.number),

                      Column(
                        children: [
                          ...recipients.asMap().entries.map((entry) {
                            int index = entry.key;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputField(
                                        hintText:
                                            "Téléphone destinataire ${index + 1}",
                                        controller: recipients[index]["phone"],
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomInputField(
                                        hintText: "Montant (XAF)",
                                        controller: recipients[index]["amount"],
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {
                                            updateTotalAmount();
                                          });
                                        },
                                      ),
                                    ),
                                    if (index >= 0)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            updateTotalAmount();
                                            recipients.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            );
                          }),

                          // Ajouter destinataire si abonnement actif
                          if (hasSubscription && recipients.length < 3)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Ajouter un destinataire"),
                              onPressed: () {
                                setState(() {
                                  recipients.add({
                                    "phone": TextEditingController(),
                                    "amount": TextEditingController()
                                      ..addListener(() {
                                        updateTotalAmount();
                                      })
                                  });
                                  amountController.clear();
                                });
                              },
                            ),

                          // Invitation à s'abonner
                          if (!hasSubscription)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SubscriptionPage(data: widget.data),
                                  ),
                                );
                              },
                              child: Text(
                                "Activer un abonnement pour ajouter d'autres destinataires",
                                style: TextStyle(
                                    color: Color.fromARGB(185, 17, 120, 179)),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: applyWithdrawalFee,
                            onChanged: (val) {
                              setState(() {
                                applyWithdrawalFee = val!;
                                updateTotalAmount();
                              });
                            },
                          ),
                          const Text(
                            "Frais de retrait (3 %)",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (applyWithdrawalFee && totalAmount != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              getWithdrawalFeeText(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      // choisir entre faire le dépot sur une durée ou juste un jour
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Row(
                                    children: [
                                      // Bloc "Un jour"
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            // color: disbursementMode == "one_day"
                                            //     ?const Color.fromARGB(255, 224, 229, 232)
                                            //     :  const Color.fromARGB(255, 255, 255, 255), // Fond spécial pour UN JOUR
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue.shade300,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Radio<String>(
                                                value: "one_day",
                                                groupValue: disbursementMode,
                                                onChanged: (val) {
                                                  setState(() {
                                                    disbursementMode = val!;
                                                    endDate =
                                                        startDate; // même jour
                                                    selectedDays = {
                                                      startDate.weekday
                                                    };
                                                  });
                                                },
                                                activeColor: Colors.blue,
                                              ),
                                              const Text(
                                                "UN JOUR",
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Bloc "Plusieurs jours"
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            // color: disbursementMode ==
                                            //         "multi_days"
                                            //     ? const Color.fromARGB(255, 255, 255, 255) // Fond spécial pour UN JOUR
                                            //     : const Color.fromARGB(255, 224, 229, 232), // non sélectionné
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.green.shade300,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Radio<String>(
                                                value: "multi_days",
                                                groupValue: disbursementMode,
                                                onChanged: (val) {
                                                  setState(() {
                                                    disbursementMode = val!;
                                                    endDate = null;
                                                    selectedDays =
                                                        {}; // libérer pour la sélection
                                                  });
                                                },
                                                activeColor: Colors.green,
                                              ),
                                              const Text(
                                                "PLUSIEURS JOURS",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (disbursementMode == "multi_days")
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          bottom: 8.0, left: 4.0),
                                      child: Text(
                                        "Sélectionner les dates",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          title: Text(
                                            disbursementMode == "one_day"
                                                ? "Date: ${formatDate(startDate)}"
                                                : "Début: ${formatDate(startDate)}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          leading:
                                              const Icon(Icons.calendar_today),
                                          onTap: () =>
                                              _selectStartDate(context),
                                        ),
                                      ),
                                      if (disbursementMode == "multi_days")
                                        Expanded(
                                          child: ListTile(
                                            title: Text(
                                              "Fin: ${formatDate(endDate)}",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            leading: const Icon(
                                                Icons.calendar_today),
                                            onTap: () =>
                                                _selectEndDate(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (disbursementMode == "multi_days")
                                const Align(
                                    alignment: Alignment.centerLeft,
                                    heightFactor: 2,
                                    child: Text("Jours de décaissement",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14))),
                              if (disbursementMode == "multi_days")
                                Wrap(
                                  spacing: 14,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  runSpacing: 14,
                                  children:
                                      List.generate(daysOfWeek.length, (index) {
                                    return SizedBox(
                                      width:
                                          90, // ✅ Largeur fixe pour chaque élément
                                      child: FilterChip(
                                        backgroundColor:
                                            Colors.white, // ✅ Fond blanc
                                        selectedColor: Color(0xF3F3F3F3),

                                        label: Text(
                                          daysOfWeek[index],
                                          textAlign: TextAlign
                                              .center, // ✅ centrer le texte
                                        ),

                                        selected:
                                            selectedDays.contains(index + 1),
                                        onSelected: (selected) {
                                          setState(() {
                                            selected
                                                ? selectedDays.add(index + 1)
                                                : selectedDays
                                                    .remove(index + 1);
                                            updateTotalAmount();
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 5),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Color.fromARGB(125, 5, 67, 94),
                                      width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text('heure'.toUpperCase(),
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  trailing: disbursementTime != null
                                      ? Text(
                                          disbursementTime!.format(context),
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                  255, 5, 67, 94)),
                                        )
                                      : Icon(
                                          Icons.access_time,
                                          color: Color.fromARGB(255, 5, 67, 94),
                                          size: 14,
                                        ),
                                  onTap: () => _selectTime(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (disbursementMode == "multi_days")
                        ElevatedButton.icon(
                          onPressed: () => _selectExceptionDate(context),
                          icon: const Icon(
                            Icons.block,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Ajouter une exception",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 181, 43, 33),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 2, // Optionnel : petite ombre
                          ),
                        ),
                      if (disbursementMode == "multi_days")
                        const SizedBox(height: 15),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: exceptions.map((date) {
                          return Chip(
                            label: Text(formatDate(date)),
                            backgroundColor: Color(0xf3f3f3f3),
                            onDeleted: () {
                              setState(() {
                                exceptions.remove(date);
                                updateTotalAmount();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                          "Les frais de budget organisé s'élèvent à (${(rate ?? 8).toInt()} %)"
                              .toLowerCase(),
                          style: TextStyle(fontSize: 10)),
                      const Text("Montant total estimé",
                          style: TextStyle(fontSize: 16)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          "${totalAmount?.toStringAsFixed(2) ?? '0.00'} XAF",
                          key: ValueKey(totalAmount),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05445E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            await refreshUserData();
                            await handleSubmit();
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize:
                          MainAxisSize.min, // garde la taille du contenu
                      children: const [
                        Text(
                          "AJOUTER",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.send, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Applayout(
            currentIndex: currentIndex,
            onTap: handleNavTap,
            data: widget.data,
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
