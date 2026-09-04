import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AtlasApp preserves StatefulWidget public contract', () {
    final source = File('lib/app.dart').readAsStringSync();

    expect(source, contains('class AtlasApp extends StatefulWidget'));
    expect(
      source,
      contains('State<AtlasApp> createState() => _AtlasAppState();'),
    );
    expect(source, contains('class _AtlasAppState extends State<AtlasApp>'));
    expect(source, contains('class _AtlasFirstFrame extends StatelessWidget'));
    expect(source, contains('class _AtlasOperationalRoot extends StatelessWidget'));
    expect(source, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(source, contains('Timer(const Duration(milliseconds: 900)'));
  });
}
