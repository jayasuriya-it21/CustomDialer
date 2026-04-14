import 'package:flutter/material.dart';

class UiConstants {
  const UiConstants._();

  static const Duration dialpadOpenDuration = Duration(milliseconds: 280);
  static const Duration dialpadCloseDuration = Duration(milliseconds: 220);
  static const Duration searchOpenDuration = Duration(milliseconds: 200);
  static const Duration incomingCallTransitionDuration = Duration(milliseconds: 150);
  static const Duration inCallTransitionDuration = Duration(milliseconds: 200);

  static const EdgeInsets homeSearchPadding = EdgeInsets.fromLTRB(16, 6, 16, 2);
}
