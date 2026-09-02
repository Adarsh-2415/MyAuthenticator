import 'package:flutter/material.dart';

/// Centralized corner radius scale.
abstract class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double card = 16.0;
  static const double large = 24.0;

  static const BorderRadius smallBorder = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius largeBorder = BorderRadius.all(Radius.circular(large));
}
