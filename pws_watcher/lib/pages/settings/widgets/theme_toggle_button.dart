import 'package:flutter/material.dart';

// Kept for compatibility but no longer used directly by ThemeSettingsCard
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton(this.tooltip, this.color);

  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 30.0,
        height: 30.0,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
