import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A row containing two side-by-side metric cards.
class DoubleVariableRow extends StatelessWidget {
  final bool visibilityLeft;
  final String? labelLeft;
  final String? assetLeft;
  final IconData? iconLeft;
  final String? valueLeft;
  final String? unitLeft;
  final bool? visibilityRight;
  final String? labelRight;
  final String? assetRight;
  final IconData? iconRight;
  final String? valueRight;
  final String? unitRight;

  const DoubleVariableRow({
    required this.labelLeft,
    this.assetLeft,
    this.iconLeft,
    required this.valueLeft,
    required this.unitLeft,
    required this.labelRight,
    this.assetRight,
    this.iconRight,
    required this.valueRight,
    required this.unitRight,
    this.visibilityLeft = true,
    this.visibilityRight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: visibilityLeft
              ? _MetricCard(
                  value: valueLeft,
                  unit: unitLeft,
                  icon: iconLeft,
                  asset: assetLeft,
                  label: labelLeft,
                )
              : const SizedBox.shrink(),
        ),
        if (visibilityLeft && (visibilityRight ?? false))
          const SizedBox(width: 12),
        Expanded(
          child: (visibilityRight ?? false)
              ? _MetricCard(
                  value: valueRight,
                  unit: unitRight,
                  icon: iconRight,
                  asset: assetRight,
                  label: labelRight,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A frosted-glass metric card.
class _MetricCard extends StatelessWidget {
  final String? value;
  final String? unit;
  final IconData? icon;
  final String? asset;
  final String? label;

  const _MetricCard({
    required this.value,
    required this.unit,
    this.icon,
    this.asset,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label ?? '',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.18), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon + label row
                Row(
                  children: [
                    _buildIcon(context),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Value + unit row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (icon != null) {
      return Icon(icon, size: 16, color: Colors.white.withOpacity(0.6));
    }
    if (asset != null && asset!.isNotEmpty) {
      return SvgPicture.asset(
        asset!,
        width: 16,
        height: 16,
        color: Colors.white.withOpacity(0.6),
      );
    }
    return const SizedBox(width: 16);
  }
}

/// Legacy single-item row kept for backward compatibility (used in detail page, etc.)
class VariableRow extends StatelessWidget {
  final String? value;
  final String? unit;
  final IconData? icon;
  final String? asset;
  final String? label;
  final bool leftAlign;

  const VariableRow({
    required this.value,
    required this.unit,
    this.icon,
    this.asset,
    required this.label,
    this.leftAlign = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon != null
        ? Icon(icon, size: 28, color: Theme.of(context).colorScheme.secondary)
        : SvgPicture.asset(
            asset!,
            width: 28,
            height: 28,
            color: Theme.of(context).colorScheme.secondary,
          );

    final valueText = Text(
      value!,
      maxLines: 1,
      style: Theme.of(context)
          .textTheme
          .headlineSmall!
          .copyWith(color: Theme.of(context).colorScheme.secondary),
    );
    final unitText = Text(
      unit!,
      maxLines: 1,
      style: Theme.of(context)
          .textTheme
          .titleMedium!
          .copyWith(color: Theme.of(context).colorScheme.secondary),
    );

    if (leftAlign) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(right: 10), child: iconWidget),
          valueText,
          unitText,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueText,
          unitText,
          Padding(padding: const EdgeInsets.only(left: 10), child: iconWidget),
        ],
      );
    }
  }
}
