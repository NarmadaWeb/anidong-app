import 'package:flutter/material.dart';

class RadioGroup<T> extends InheritedWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static RadioGroup<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroup<T>>();
  }

  @override
  bool updateShouldNotify(RadioGroup<T> oldWidget) {
    return oldWidget.groupValue != groupValue || oldWidget.onChanged != onChanged;
  }
}
