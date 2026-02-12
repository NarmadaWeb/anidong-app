
import 'package:flutter/material.dart';
import 'package:anidong/widgets/radio_group.dart';

Widget test(String selected) {
  return AppRadioGroup<String>(
    groupValue: selected,
    onChanged: (v) {},
    child: const Column(
      children: [
        RadioGroupTile<String>(value: 'a', title: Text('A')),
        RadioGroupTile<String>(value: 'b', title: Text('B')),
      ],
    ),
  );
}
