import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Figma: Row frame 375x82, padding L24 R24
    // Inner icon row: ic-menu (24x24) | logo (163x26) centered | ic-power (24x24)
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 82,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ic-menu SVG (real Figma)
              GestureDetector(
                onTap: () {},
                child: SvgPicture.asset(
                  'assets/icons/ic-menu.svg',
                  width: 24,
                  height: 24,
                ),
              ),

              // Logo centered (Figma: 163×26)
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/img-logo.png',
                    height: 26,
                    width: 163,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ic-power SVG (real Figma)
              GestureDetector(
                onTap: () {},
                child: SvgPicture.asset(
                  'assets/icons/ic-power.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
