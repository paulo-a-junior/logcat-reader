import 'package:flutter/material.dart';

/// Colours a filter can be tagged with; [SavedFilter.colorIndex] indexes it.
const filterPalette = <MaterialColor>[
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
];

Color filterColor(int index, Brightness brightness) {
  final c = filterPalette[index % filterPalette.length];
  return brightness == Brightness.dark ? c.shade300 : c.shade700;
}
