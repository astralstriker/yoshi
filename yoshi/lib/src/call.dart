import 'dart:io';

class Call<T> {
  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  final HttpHeaders headers;

  final T data;

  Call({this.statusCode, this.reasonPhrase, this.headers, this.data});
}

class HttpHeader {
  final String name;
  final String value;

  HttpHeader(this.name, this.value);
}

class HttpHeaders {
  Map<String, String> _headers;

  HttpHeaders() {
    _headers = {};
  }

  void add(HttpHeader header) {
    _headers[header.name] = header.value;
  }

  factory HttpHeaders.fromMap(Map<String, String> headers) {
    final instance = HttpHeaders();
    instance._headers.addAll(headers);
    return instance;
  }

  void remove(HttpHeader header) {
    _headers.remove(header.name);
  }
}
