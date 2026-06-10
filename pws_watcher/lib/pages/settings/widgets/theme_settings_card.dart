import 'package:flutter/material.dart';
import 'package:pws_watcher/get_it_setup.dart';
import 'package:pws_watcher/services/theme_service.dart';

class ThemeSettingsCard extends StatefulWidget {
  final ThemeService? themeService = getIt<ThemeService>();

  @override
  _ThemeSettingsCardState createState() => _ThemeSettingsCardState();
}

class _ThemeSettingsCardState extends State<ThemeSettingsCard> {
  var _themeSelection = [true, false, false, false, false];

  @override
  void initState() {
    _themeSelection = [
      widget.themeService!.activeTheme == "day",
      widget.themeService!.activeTheme == "evening",
      widget.themeService!.activeTheme == "night",
      widget.themeService!.activeTheme == "grey",
      widget.themeService!.activeTheme == "blacked",
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.palette_outlined,
                    color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  "Theme",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildThemeChip(0, "Day", const Color(0xFF1565C0)),
                _buildThemeChip(1, "Evening", const Color(0xFFE65100)),
                _buildThemeChip(2, "Night", const Color(0xFF311B92)),
                _buildThemeChip(3, "Storm", const Color(0xFF37474F)),
                _buildThemeChip(4, "AMOLED", Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(int index, String label, Color color) {
    final bool selected = _themeSelection[index];
    return GestureDetector(
      onTap: () => _onThemeSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: selected ? 0 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onThemeSelected(int index) {
    setState(() {
      for (int i = 0; i < _themeSelection.length; i++) {
        _themeSelection[i] = i == index;
      }
    });
    const themes = ["day", "evening", "night", "grey", "blacked"];
    widget.themeService!.setTheme(themes[index]);
  }
}
