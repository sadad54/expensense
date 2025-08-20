import 'package:flutter/material.dart';

class SocialButtonsRow extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onFacebook;

  const SocialButtonsRow({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          tooltip: 'Continue with Google',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          border: Border.all(color: Colors.grey.shade300),
          onPressed: onGoogle,
          child: Image.asset(
            'assets/images/google.png',
            width: 22,
            height: 22,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          tooltip: 'Continue with Apple',
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          onPressed: onApple,
          child: const Icon(Icons.apple),
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          tooltip: 'Continue with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          foregroundColor: Colors.white,
          onPressed: onFacebook,
          child: Image.asset(
            'assets/images/facebook.png',
            width: 22,
            height: 22,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Color backgroundColor,
    required Color foregroundColor,
    required Widget child,
    required VoidCallback onPressed,
    String? tooltip,
    BoxBorder? border,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: backgroundColor,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          onTap: onPressed,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: border,
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(color: foregroundColor),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
