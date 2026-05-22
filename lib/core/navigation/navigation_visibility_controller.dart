import 'package:flutter/material.dart';

final ValueNotifier<bool> homeChromeVisibleNotifier = ValueNotifier(true);

void setHomeChromeVisible(bool isVisible) {
  if (homeChromeVisibleNotifier.value == isVisible) {
    return;
  }

  homeChromeVisibleNotifier.value = isVisible;
}
