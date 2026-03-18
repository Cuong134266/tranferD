import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewAllButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const ViewAllButton({super.key, this.text = 'Tất cả', this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: const Color(0xFF7A8DA3), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 18 / 13,
                color: const Color(0xFF495363),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Color(0xFF495363),
            ),
          ],
        ),
      ),
    );
  }
}
