import 'package:flutter/painting.dart';

class AppRadii {
  AppRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xxl = 32;
  static const double full = 999;

  // Convenience BorderRadius constructors
  static BorderRadius circular(double r) => BorderRadius.circular(r);
  static const xsAll = BorderRadius.all(Radius.circular(xs));
  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const fullAll = BorderRadius.all(Radius.circular(full));

  // Sheet: round top only
  static const sheetTop = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}
