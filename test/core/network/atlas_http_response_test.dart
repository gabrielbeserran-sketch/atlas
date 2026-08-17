import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

void main() {
  test('asMap aceita objeto JSON', () {
    const response = AtlasHttpResponse(
      statusCode: 200,
      body: {'ok': true},
      headers: {},
    );
    expect(response.asMap()['ok'], isTrue);
  });

  test('asMapList aceita lista de objetos JSON', () {
    const response = AtlasHttpResponse(
      statusCode: 200,
      body: [
        {'id': 1},
      ],
      headers: {},
    );
    expect(response.asMapList().single['id'], 1);
  });

  test('asMap rejeita corpo incompatível', () {
    const response = AtlasHttpResponse(statusCode: 200, body: [], headers: {});
    expect(response.asMap, throwsA(isA<AtlasHttpException>()));
  });
}
