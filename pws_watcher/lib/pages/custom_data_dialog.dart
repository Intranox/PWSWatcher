import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PWSTemperatureRow extends StatelessWidget {
  const PWSTemperatureRow(this.temperature, {this.asset, Key? key})
      : super(key: key);

  final String temperature;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AutoSizeText(
                    temperature,
                    minFontSize: 56.0,
                    maxFontSize: 72.0,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                if (asset != null) ...[
                  const SizedBox(width: 16),
                  SvgPicture.asset(asset!, width: 72.0, height: 72.0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
