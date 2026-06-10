import 'dart:math';
import 'package:flutter/material.dart';

class DotsIndicator extends AnimatedWidget {
  DotsIndicator({
    required this.controller,
    this.itemCount,
    this.onPageSelected,
    this.color = Colors.white,
  }) : super(listenable: controller);

  final PageController controller;
  final int? itemCount;
  final ValueChanged<int>? onPageSelected;
  final Color color;

  static const double _kDotSize = 6.0;
  static const double _kActiveDotWidth = 20.0;
  static const double _kDotSpacing = 10.0;

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    final double width =
        _kDotSize + (_kActiveDotWidth - _kDotSize) * selectedness;

    return GestureDetector(
      onTap: () => onPageSelected?.call(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _kDotSpacing / 2),
        width: width,
        height: _kDotSize,
        decoration: BoxDecoration(
          color: color.withOpacity(0.4 + 0.6 * selectedness),
          borderRadius: BorderRadius.circular(_kDotSize / 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount!, _buildDot),
    );
  }
}
