import 'package:flutter/material.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/pages/service/PolitiqueScreen.dart';
import 'package:frontend/pages/service/SuccessScreen.dart';
import 'package:frontend/pages/LoginScreen.dart';
import 'package:frontend/pages/service/qrCode/qrScan.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeCommercialController = TextEditingController();
  bool _obscureText = true;
  bool acceptConditions = false;
  final ApiService apiService = ApiService();

  void showPolitiqueDialog() {
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

void register() async {
  if (passwordController.text.length < 8) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text("Le mot de passe doit contenir au moins 8 caractères.")),
    );
    return;
  }
  if (acceptConditions == false) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text("Vous devez accepter les conditions d'utilisations.")),
    );
    return;
  }

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    var data = await apiService.register(
      nameController.text,
      phoneNumberController.text,
      passwordController.text,
      codeCommercialController.text,
    );

    if (!context.mounted) return;

    Navigator.of(context).pop(); // Fermer le loading dialog

    if (data != null) {
      // Ici on affiche toujours le message du backend
      String message = data["message"] ?? "Inscription réussie !";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (data["success"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(data: data["data"]),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'inscription.")),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Fermer le loading dialog en cas d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Une erreur est survenue : $e")),
      );
    }
  }
}

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 249, 249, 249), Color(0xFF189AB4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
            'assets/images/inscription.png',
            height: 200.0,
            color: const Color(0xFF0C405A),
          ),
              const SizedBox(height: 2),
              Text(
                "S'inscrire",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              // RichText(
              //   textAlign: TextAlign.center,
              //   text: TextSpan(
              //     style: GoogleFonts.poppins(fontSize: 14),
              //     children: const [
              //       TextSpan(
              //           text: "Inscrivez vous maintenant et profitez de nos "),
              //       TextSpan(
              //         text: "services",
              //         style: TextStyle(color: Color(0xFFF4D35E)),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 30),
              // Formulaire
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomInputField(hintText : "Nom", controller: nameController,icon: Icons.person,),
                    CustomInputField(hintText :"Numéro de tel",
                        controller: phoneNumberController,
                        keyboardType: TextInputType.phone,icon: Icons.phone_android,),
                    CustomInputField(hintText : "Mot de passe",
                        controller: passwordController,  isPassword: true, icon: Icons.lock,),
                    ReferralField(controller: codeCommercialController),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: acceptConditions,
                          hoverColor: Colors.teal,
                          onChanged: (v) {
                            setState(() {
                              acceptConditions = v ?? false;
                            });
                          },
                        ),
                        // const Text("J'accepte les "),
                        GestureDetector(
                          onTap: showPolitiqueDialog,
                          child: const Text(
                            "J'accepte les conditions",
                            style: TextStyle(
                              color: Color(0xFF05445E),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                        onPressed: register,
                        child: const Text(
                          "Inscription",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(253, 255, 255, 255)),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Vous avez déjà un compte ? Se connecter',  style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
}
