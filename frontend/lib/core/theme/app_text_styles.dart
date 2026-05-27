import 'package:flutter/material.dart';

/// Typography scale matching the MedGraph design spec.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle largeTitle = TextStyle(
    fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
  );
  static const TextStyle subheadline = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
  );
}
