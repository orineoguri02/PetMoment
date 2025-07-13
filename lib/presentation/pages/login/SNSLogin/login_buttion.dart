import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final Color color;
  final Widget? image;
  final IconData? icon;
  final String text;
  final Color textColor;
  final VoidCallback onPressed;
  final Color? borderColor;

  const LoginButton({
    super.key,
    required this.color,
    this.image,
    this.icon,
    required this.text,
    required this.textColor,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 309,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Flexible(
                child: image!,
              ),
            if (icon != null)
              Flexible(
                child: Icon(icon, color: textColor),
              ),
            if (image != null || icon != null) const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
