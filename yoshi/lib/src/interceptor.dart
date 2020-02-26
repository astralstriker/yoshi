import 'package:http/http.dart';

abstract class BaseInterceptor {}

abstract class ResponseInterceptor extends BaseInterceptor {
  onInterceptResponse(Response response);
}

abstract class RequestInterceptor extends BaseInterceptor {
  BaseRequest onInterceptRequest(BaseRequest request);
}
