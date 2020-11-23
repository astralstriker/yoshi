// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

// **************************************************************************
// YoshiGenerator
// **************************************************************************

class ApiService extends Api with _$Api {
  ApiService() {
    _client = YoshiClient();
  }

  ApiService.withClient(YoshiClient client) {
    _client = client;
  }
}

mixin _$Api implements Api {
  YoshiClient _client;

  @override
  Future<Call> postsByUserId(String userId) async {
    final res = await _client.get('${_client.baseUrl}/posts?userId=$userId');
    return Call(
      data: json.decode(res.body),
      statusCode: res.statusCode,
      reasonPhrase: res.reasonPhrase,
      headers: HttpHeaders.fromMap(res.headers),
    );
  }
}
