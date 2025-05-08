import 'package:flutter/foundation.dart';

class HomeState extends ChangeNotifier {
  bool _inGroup = false;

  bool get inGroup => _inGroup;

  void toggleIsSomething() {
    _inGroup = !_inGroup;
    notifyListeners();
  }
}
