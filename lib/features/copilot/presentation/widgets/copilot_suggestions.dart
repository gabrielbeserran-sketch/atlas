import 'package:flutter/material.dart';

class CopilotSuggestions extends StatelessWidget {
  const CopilotSuggestions({
    required this.suggestions,
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final List<String> suggestions;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text(suggestion),
              onPressed: enabled
                  ? () {
                      onSelected(suggestion);
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
