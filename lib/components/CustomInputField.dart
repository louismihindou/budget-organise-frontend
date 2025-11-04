import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? icon;

  const CustomInputField({
    Key? key,
    required this.hintText,
    this.isPassword = false,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.icon, 
    Function(dynamic value)? onChanged, // Nouvelle propriété pour l'icône
  }) : super(key: key);

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color.fromARGB(255, 63, 62, 62).withOpacity(0.3), // Couleur de l'ombre
              blurRadius: 6, // Flou
              offset: const Offset(0, 3), // Décalage de l'ombre
            ),
          ],
        ),
        child: TextField(
          style: TextStyle(fontSize: 12),
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hintText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF05445E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF05445E)),
            ),
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, color: Color(0xFF05445E))
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF05445E),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
