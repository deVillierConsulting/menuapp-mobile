import 'package:flutter/painting.dart';

// Two-layer, low-alpha shadows — never use Material's elevation int.
// Each level has a tight near-shadow and a soft far-shadow.
// The ink color (0xFF1C1917) at low opacity gives a warm shadow tone.

const e0 = [
  BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 1), blurRadius: 2),
];

const e1 = [
  BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 2), blurRadius: 6),
];

const e2 = [
  BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 2), blurRadius: 6),
  BoxShadow(color: Color(0x0F1C1917), offset: Offset(0, 10), blurRadius: 22),
];

const e3 = [
  BoxShadow(color: Color(0x121C1917), offset: Offset(0, 8), blurRadius: 24),
  BoxShadow(color: Color(0x171C1917), offset: Offset(0, 22), blurRadius: 48),
];
