
import 'package:flutter/material.dart';

Widget test(String selected) {
  return RadioGroup<String>(
    groupValue: selected,
    onChanged: (v) {},
    child: const Column(
      children: [
        RadioListTile<String>(value: 'a', title: Text('A')),
        RadioListTile<String>(value: 'b', title: Text('B')),
      ],
    ),
  );
}
