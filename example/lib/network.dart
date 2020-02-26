import 'package:example/api.dart';
import 'package:yoshi/yoshi.dart';

final client = YoshiClient(
    baseUrl: 'https://jsonplaceholder.typicode.com', interceptors: [
      HttpLogger(),
    ]);

final apiService = ApiService.withClient(client);
