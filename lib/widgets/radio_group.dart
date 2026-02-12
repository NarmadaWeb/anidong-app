import 'package:flutter/material.dart';

class AppRadioGroup<T> extends InheritedWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const AppRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  static AppRadioGroup<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppRadioGroup<T>>();
  }

  @override
  bool updateShouldNotify(AppRadioGroup<T> oldWidget) {
    return oldWidget.groupValue != groupValue || oldWidget.onChanged != onChanged;
  }
}

class RadioGroupTile<T> extends StatelessWidget {
  final T value;
  final Widget title;
  final Color? activeColor;
  final EdgeInsetsGeometry contentPadding;
  final VisualDensity visualDensity;

  const RadioGroupTile({
    super.key,
    required this.value,
    required this.title,
    this.activeColor,
    this.contentPadding = EdgeInsets.zero,
    this.visualDensity = VisualDensity.compact,
  });

  @override
  Widget build(BuildContext context) {
    final radioGroup = AppRadioGroup.of<T>(context);
    if (radioGroup == null) {
      throw FlutterError('RadioGroupTile must be a descendant of AppRadioGroup');
    }

    return RadioListTile<T>(
      value: value,
      groupValue: radioGroup.groupValue,
      onChanged: radioGroup.onChanged,
      title: title,
      activeColor: activeColor,
      contentPadding: contentPadding,
      visualDensity: visualDensity,
    );
  }
}
