import 'package:flutter/material.dart';

class AtlasMetricCard extends StatelessWidget {
  const AtlasMetricCard({required this.label, required this.value, super.key});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: ListTile(
        title: Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        subtitle: Text(label.replaceAll('_', ' ')),
      ),
    ),
  );
}
