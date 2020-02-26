import 'package:http/http.dart';
import 'interceptor.dart';

enum LoggingLevel { BODY, HEADER, BASIC, NONE }

/* 
An example implelmentation of BaseInterceptor
================================================
*/

class HttpLogger implements ResponseInterceptor {
  final LoggingLevel loggingLevel;
  HttpLogger([this.loggingLevel = LoggingLevel.BODY]);


  @override
  onInterceptResponse(Response response) {
    switch (loggingLevel) {
      case LoggingLevel.BODY:
        print(
            'STATUS: ${response.statusCode} ${response.reasonPhrase}\nURL: ${response.request.url}\nBODY: ${response.body}');
        break;
      case LoggingLevel.HEADER:
        print(
            'STATUS: ${response.statusCode} ${response.reasonPhrase}\nURL: ${response.request.url}\nHEADERS: ${response.request.headers}');
        break;
      case LoggingLevel.BASIC:
        print(
            'STATUS: ${response.statusCode} ${response.reasonPhrase}\nURL: ${response.request.url}');
        break;
      case LoggingLevel.NONE:
        break;
    }
  }
}
