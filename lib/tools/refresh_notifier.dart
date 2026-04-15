import 'package:flutter/foundation.dart';

class RefreshNotifier {
  static final RefreshNotifier _instance = RefreshNotifier._internal();
  factory RefreshNotifier() => _instance;
  RefreshNotifier._internal();

  // A simple counter that incrementing triggers listeners
  final ValueNotifier<int> refreshCounter = ValueNotifier<int>(0);

  void notifyRefresh() {
    refreshCounter.value++;
  }

}