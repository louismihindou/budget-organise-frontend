import 'package:flutter/material.dart';

class CustomGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final double borderRadius;
  final double height;
  final TextStyle? textStyle;

  const CustomGradientButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradientColors,
    this.borderRadius = 30.0,
    this.height = 48.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [const Color(0xFF0C405A), const Color(0xFF1178B3)]; // bleu par défaut

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: textStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
