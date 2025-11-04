import 'package:flutter/material.dart';
import 'package:frontend/components/CustomInputField.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/pages/Inscription.dart';
import 'package:frontend/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();
  bool _obscureText = true;

  void login() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var data = await apiService.login(phoneController.text.replaceAll(' ', ''), passwordController.text);
    Navigator.of(context).pop(); // Fermer le loading dialog

    if (data != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Connexion réussie !")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(data: data), // Aucune donnée à passer
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Numéro de téléphone ou mot de passe incorrecte ")));
    }
  }

  @override
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
              // Image + icône crayon (utiliser un Asset à la place si besoin)
              Image.asset(
            'assets/images/inscription.png',
            height: 200.0,
            color: const Color(0xFF0C405A),
          ),
              const SizedBox(height: 10),

              Text(
                "Se connecter",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 14),
                  children: const [
                    TextSpan(
                        text:
                            "Connectez vous maintenant pour visitez vos plannification et profitez de nos "),
                    TextSpan(
                      text: "services",
                      style: TextStyle(color: Color(0xFFF4D35E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
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
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // Pour occuper toute la largeur
                  children: [
                    CustomInputField(hintText :"Numéro de téléphone",
                        controller: phoneController,icon: Icons.phone_android,),
                     CustomInputField(hintText : "Mot de passe",
                        controller: passwordController,  isPassword: true, icon: Icons.lock,),
                    const SizedBox(height: 10),
                      SizedBox(height: 10),
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
                        onPressed: login,
                        child: const Text(
                          "Se connnecter",
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(253, 255, 255, 255)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Inscription(),
                          ),
                        );
                      },
                      child:
                          const Text("Vous n'avez pas encore de compte ? S'inscrire",textAlign: TextAlign.center, style: TextStyle(fontSize: 14),),
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
