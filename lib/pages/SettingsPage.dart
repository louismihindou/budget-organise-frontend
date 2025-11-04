import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/Layouts/AppLayout.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/pages/DisbursementPage.dart';
import 'package:frontend/pages/EventNotePage.dart';
import 'package:frontend/pages/SubscriptionPage.dart';
import 'package:frontend/pages/HistoryPage.dart';
import 'package:frontend/pages/LoginScreen.dart';
import 'package:frontend/pages/service/PolitiqueScreen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const SettingsPage({super.key, required this.data});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int currentIndex = 3;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool isUpdating = false;
  String? referralCode;
  final ApiService apiService = ApiService();
  final GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() => isUpdating = true);
    final response = await apiService.getUserProfile(widget.data['token']);
    if (response != null && mounted) {
      final updatedUser = response['user'];
      setState(() {
        referralCode = updatedUser?['referral_code'];
        isUpdating = false;
      });
    } else {
      setState(() => isUpdating = false);
    }
  }

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
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Budget Organisé',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _sectionTitle("Informations"),
         
          ListTile(
            title: Text("Mes Ayant-droits"),
            onTap: () => _showManageBeneficiariesDialog(context),
          ),
          ListTile(
            title: Text("Mon QR Code"),
            onTap: () => _showQrDialog(context),
          ),
          _sectionTitle("Compte"),
          ListTile(
            title: Text("Changer nom d’utilisateur"),
            onTap: () => _showChangeNameDialog(context),
          ),
          ListTile(
            title: Text("Changer de Mot de Passe"),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            title: Text("Se déconnecter"),
            onTap: () => _showLogoutDialog(context),
          ),
          _sectionTitle("Aide"),
           ListTile(
            title: Text("A propos de B.O"),
            onTap: () => _showAboutDialog(context),
          ),
        ListTile(
            title: Text("Laisser un commentaire"),
            onTap: () => _showCommentDialog(context),
          ),],
      ),
      bottomNavigationBar: Applayout(
        currentIndex: currentIndex,
        onTap: handleNavTap,
        data: widget.data,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      color: Color(0xFF065F8C),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
void _showManageBeneficiariesDialog(BuildContext context) {
  // Copie locale pour modification
  List<Map<String, String>> beneficiaries = List<Map<String, String>>.from(
      widget.data['beneficiaries'] ?? []);

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text(
          "Mes Ayant-droits",
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Liste des bénéficiaires
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: beneficiaries.length,
                  itemBuilder: (context, index) {
                    final b = beneficiaries[index];
                    final nameController = TextEditingController(text: b['name']);
                    final phoneController = TextEditingController(text: b['phone']);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: "Nom",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                beneficiaries[index]['name'] = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Numéro",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                beneficiaries[index]['phone'] = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                beneficiaries.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Ajouter un bénéficiaire
              if (beneficiaries.length < 2)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      beneficiaries.add({'name': '', 'phone': ''});
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter un ayant-droit"),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () async {
                // Validation simple
                for (var b in beneficiaries) {
                  if (b['name']!.isEmpty || b['phone']!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tous les champs doivent être remplis")),
                    );
                    return;
                  }
                }

                // Appel API pour sauvegarder les ayant-droits
                final success = await apiService.updateBeneficiaries(beneficiaries:beneficiaries , token: widget.data['token']);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ayant-droits mis à jour")));
                  setState(() {
                    widget.data['beneficiaries'] = beneficiaries;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erreur lors de la mise à jour")));
                }
              },
              child: const Text("Enregistrer")),
        ],
      ),
    ),
  );
}

  void _showChangeNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Changer votre nom d'utilisateur",
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: CustomInputField(
          hintText: "Nouveau nom",
          controller: _nameController,
        ),
        actions: [
          TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: _isLoading ? null : _changeName,
            child: _isLoading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Valider"),
          ),
        ],
      ),
    );
  }
void _showCommentDialog(BuildContext context) {
  final TextEditingController _commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Laisser un commentaire"),
      content: CustomInputField(
        hintText: "Votre commentaire...",
        controller: _commentController,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler")),
        ElevatedButton(
            onPressed: () async {
              final comment = _commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez entrer un commentaire")),
                );
                return;
              }

              // Appel API pour enregistrer le commentaire
              final success =  await apiService.sendComment(comment, token : widget.data['token']);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Commentaire envoyé avec succès")),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erreur lors de l'envoi du commentaire")),
                );
              }
            },
            child: const Text("Envoyer")),
      ],
    ),
  );
}

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInputField(hintText: "Ancien mot de passe", controller: oldPasswordController, isPassword: true, icon: Icons.lock),
            CustomInputField(hintText: "Nouveau mot de passe", controller: newPasswordController, isPassword: true, icon: Icons.lock),
            CustomInputField(hintText: "Confirmer le nouveau mot de passe", controller: confirmPasswordController, isPassword: true, icon: Icons.lock),
          ],
        ),
        actions: [
          TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final oldPwd = oldPasswordController.text.trim();
                      final newPwd = newPasswordController.text.trim();
                      final confirmPwd = confirmPasswordController.text.trim();
                      if (newPwd != confirmPwd) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Les mots de passe ne correspondent pas.")),
                        );
                        return;
                      }
                      _changePassword(oldPwd, newPwd, confirmPwd);
                    },
              child: _isLoading
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("Changer")),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Déconnexion"),
        content: Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                logout();
              },
              child: Text("Se déconnecter")),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: const PolitiqueScreen(),
          ),
        );
      },
    );
  }

  // 🎯 QR Code avec partage et téléchargement
  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: referralCode == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Mon Code Parrainage",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      RepaintBoundary(
                        key: globalKey,
                        child: QrImageView(
                          data: referralCode!,
                          version: QrVersions.auto,
                          size: 250,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        referralCode!,
                        style: const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                      // const SizedBox(height: 10),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     ElevatedButton.icon(
                      //         icon: Icon(Icons.share),
                      //         label: Text("Partager"),
                      //         onPressed: () async => await _shareQrCode()),
                      //     const SizedBox(width: 10),
                      //     ElevatedButton.icon(
                      //         icon: Icon(Icons.download),
                      //         label: Text("Télécharger"),
                      //         onPressed: () async => await _saveQrCode()),
                      //   ],
                      // )
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _shareQrCode() async {
    try {
      final boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/referral_qr.png').writeAsBytes(pngBytes);

      await Share.shareXFiles(file.path as List<XFile>, text: "Mon code parrainage : $referralCode");
    } catch (e) {
      print("Erreur partage QR: $e");
    }
  }

  Future<void> _saveQrCode() async {
    try {
      final boundary = globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final file = await File('${directory.path}/referral_qr.png').writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR Code sauvegardé dans ${file.path}")),
      );
    } catch (e) {
      print("Erreur sauvegarde QR: $e");
    }
  }

  void logout() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    bool success = await apiService.logout(widget.data['token']);
    Navigator.of(context).pop();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Déconnexion réussie")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la déconnexion")));
    }
  }

  void _changeName() async {
    final name = _nameController.text.trim();
    setState(() => _isLoading = true);

    try {
      final success = await apiService.changeName(name: name, token: widget.data['token']);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changement de nom effectué avec succès")));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    setState(() => _isLoading = true);
    try {
      final success = await apiService.changePassword(
          oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword, token: widget.data['token']);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mot de passe changé avec succès")));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
