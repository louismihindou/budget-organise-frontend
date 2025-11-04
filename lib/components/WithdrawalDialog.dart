import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/services/notificationservice.dart';

class WithdrawalDialog extends StatefulWidget {
  final String token;
  final String? walletName;
  final double? rate;
  final double? initialAmount;

  const WithdrawalDialog(this.token,
      {this.rate, this.walletName, this.initialAmount, Key? key})
      : super(key: key);

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  double _totalWithFees = 0.0;
  double _fee = 0.0;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool otherNumber = false;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
      _calculateTotal();
    }
    _amountController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rateApp = (widget.rate != null ? (widget.rate! / 100) : 0.08);
    // Montant brut pour couvrir le net demandé + frais fixes
    double total = amount / (1 - rateApp);

    setState(() {
      _totalWithFees = total.ceilToDouble(); // montant débité au client
      _fee =
          (_totalWithFees - amount).ceilToDouble(); // différence = frais totaux
    });
  }

  void pollTransactionStatus(String transactionId) async {
    const maxAttempts = 10;
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;

      NotificationService.showNotification(
        id: 1,
        title: 'Retrait',
        body: 'Votre compte a été débité avec succès !',
      );

      break;
    }
  }

  bool isValidRecipient(String phone, String walletType) {
    const airtelPrefixes = ['077', '074', '076'];
    const mobicashPrefixes = ['062', '065', '066'];

    if (walletType == "AIRTEL_MONEY") {
      return airtelPrefixes.any((prefix) => phone.startsWith(prefix));
    } else if (walletType == "MOOV_MONEY") {
      return mobicashPrefixes.any((prefix) => phone.startsWith(prefix));
    }
    return false; // si wallet inconnu
  }

  Future<void> _submitWithdrawal() async {
    final amount = double.tryParse(_amountController.text.trim());
    final walletName = widget.walletName;
    if (amount == null || amount <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Montant invalide"),
          content: const Text(
            "Veuillez saisir un montant valide s'il vous plait.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      return;
    }
    if (amount <= 250 || amount >= 1000000) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Montant non correcte"),
          content: const Text(
            "Veuillez saisir un montant compris en 250 et 1 000 000 s'il vous plait.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (otherNumber && !isValidRecipient(phoneController.text, walletName!)) {
     showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
        title: const Text("Destinataire invalide"),
        content: const Text(
          "Le destinataire doit utiliser le même service mobile que vous.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),);
      return;
    }
    if (otherNumber && passwordController.text.trim().isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Mot de passe invalide"),
          content: const Text(
            "Veuillez saisir votre mot de passe.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.submitWithDraw(
        amount: _totalWithFees,
        type: 'retrait',
        phone: phoneController.text.replaceAll(' ', ''),
        password: passwordController.text.replaceAll(' ', ''),
        token: widget.token,
      );

      if (response!.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${response.message}")));
        Navigator.of(context).pop();
        pollTransactionStatus(response.data as String);
      }
    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
      AlertDialog(
        title: const Text("Erreur reseau"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Retrait",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF05445E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Veuillez indiquer le montant que vous souhaitez retirer.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Champ de saisie
              CustomInputField(
                hintText: "Montant du Retrait",
                controller: _amountController,
                isPassword: false,
                icon: Icons.money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              // const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: otherNumber,
                    onChanged: (val) {
                      setState(() {
                        otherNumber = val!;
                        if (!otherNumber) {
                          phoneController.clear();
                        }
                      });
                    },
                  ),
                  const Text(
                    "Ajouter un destinataire",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (otherNumber)
                CustomInputField(
                  hintText: "numero destinataire",
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
              const SizedBox(height: 8),
              if (otherNumber)
                CustomInputField(
                  hintText: "Mot de passe",
                  controller: passwordController,
                  isPassword: true,
                  icon: Icons.lock,
                ),
              const SizedBox(height: 20),

              // Bloc frais et total
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 5),
                            Text("Frais (${(widget.rate ?? 8).toInt()} %)"),
                          ],
                        ),
                        Text(
                          "${_fee.toStringAsFixed(2)} XAF",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 15, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Montant total débité",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${_totalWithFees.toStringAsFixed(2)} XAF",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF05445E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05445E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Confirmer",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
