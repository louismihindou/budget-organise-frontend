import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/services/notificationservice.dart';

class DepositDialog extends StatefulWidget {
  final String token;
  final double? initialAmount;
  const DepositDialog(this.token, {this.initialAmount, Key? key})
      : super(key: key);

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class FeeRange {
  final double min;
  final double max;
  final double fixedFee; // frais fixe en CFA
  final double percentFee; // frais en % du montant

  FeeRange({
    required this.min,
    required this.max,
    this.fixedFee = 0,
    this.percentFee = 0,
  });
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  double _fee = 0.0;
  double _totalWithFees = 0.0;

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

// Exemple : frais pour retrait d'espèces (à adapter selon ta grille)
  final List<FeeRange> withdrawalFees = [
    FeeRange(min: 0, max: 1000, fixedFee: 10),
    FeeRange(min: 1001, max: 5000, fixedFee: 50),
    FeeRange(min: 5001, max: 10000, fixedFee: 100),
    FeeRange(min: 10001, max: 20000, fixedFee: 150),
    FeeRange(min: 20001, max: 30000, fixedFee: 200),
    FeeRange(min: 30001, max: 40000, fixedFee: 250),
    FeeRange(min: 40001, max: 50000, fixedFee: 300),
    FeeRange(min: 50001, max: 60000, fixedFee: 350),
    FeeRange(min: 60001, max: 70000, fixedFee: 400),
    FeeRange(min: 70001, max: 80000, fixedFee: 450),
    FeeRange(min: 80001, max: 90000, fixedFee: 500),
    FeeRange(min: 90001, max: 100000, fixedFee: 550),
    FeeRange(min: 100001, max: 150000, fixedFee: 600),
    FeeRange(min: 150001, max: 166670, fixedFee: 650),
    FeeRange(min: 166671, max: 250000, fixedFee: 700),
    FeeRange(min: 250001, max: 300000, fixedFee: 750),
    FeeRange(min: 300001, max: 350000, fixedFee: 800),
    FeeRange(min: 350001, max: 400000, fixedFee: 850),
    FeeRange(min: 400001, max: 450000, fixedFee: 900),
    FeeRange(min: 450001, max: 500000, fixedFee: 1000),
  ];

// Calcul frais selon montant
  double calculateWithdrawalFee(double amount) {
    for (var range in withdrawalFees) {
      if (amount >= range.min && amount <= range.max) {
        return range.fixedFee;
      }
    }
    // si hors intervalle, par défaut 1% (ou 0)
    return (amount * 0.01);
  }

void _calculateTotal() {
  final amount = double.tryParse(_amountController.text.trim()) ?? 0;
  double percent = 0.025; // 2.5% intégrateur
  double? total;
  double? feeApplied;

  for (var range in withdrawalFees) {
    double fee = range.fixedFee;
    // Calcul brut hypothétique
    double possibleTotal = (amount + fee) / (1 - percent);

    // Vérifie si le brut tombe bien dans la tranche
    if (possibleTotal >= range.min && possibleTotal <= range.max) {
      total = possibleTotal;
      feeApplied = (possibleTotal - amount);
      break;
    }
  }

  setState(() {
    _totalWithFees = total?.ceilToDouble() ?? 0;
    _fee = feeApplied?.ceilToDouble() ?? 0;
  });
}


  void pollTransactionStatus(String transactionId) async {
    const maxAttempts = 10;
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;

      final status =
          await apiService.checkTransactionStatus(transactionId, widget.token);

      if (status == "success") {
        NotificationService.showNotification(
          id: 1,
          title: 'Recharge 💰',
          body: 'Votre compte a été crédité avec succès !',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dépôt confirmé !")),
        );

        break;
      }
    }
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un montant valide.")),
      );
      return;
    }

    // ✅ Vérification des limites
    if (amount < 250 || amount > 2500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Le montant doit être compris entre 250 XAF et 2 500 000 XAF.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionId = await apiService.submitDeposit(
        amount: _totalWithFees,
        type: 'recharge',
        token: widget.token,
      );

      if (transactionId != null) {
        Navigator.of(context).pop();
        pollTransactionStatus(transactionId as String);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
              const Text(
                "Recharger mon portefeuille",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF05445E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Indiquez le montant que vous souhaitez déposer.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Champ de saisie
              CustomInputField(
                hintText: "Montant du dépôt",
                controller: _amountController,
                isPassword: false,
                icon: Icons.money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.orange),
                            SizedBox(width: 5),
                            Text("Coût de transaction"),
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
                          "Montant total à payer",
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
                      onPressed: _isLoading ? null : _submitDeposit,
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
