import 'package:flutter/material.dart';

class AtlasModuleRoleCard extends StatelessWidget {
  const AtlasModuleRoleCard({
    required this.title,
    required this.responsibility,
    required this.doesNotReplace,
    required this.icon,
    super.key,
  });

  final String title;
  final String responsibility;
  final String doesNotReplace;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(responsibility),
                  const SizedBox(height: 6),
                  Text(
                    doesNotReplace,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
