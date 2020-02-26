import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:build/build.dart';
import 'package:yoshi/yoshi.dart' hide Constructor;
import 'package:yoshi_generator/src/annotations_processor.dart';
import 'package:yoshi_generator/src/type_helper.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

Builder yoshiGeneratorFactoryBuilder() => SharedPartBuilder(
      [YoshiGenerator()],
      'yoshi',
    );

final _annotationsProcessor = AnnotationsProcessor();
final _dartFmt = DartFormatter();
String _baseUrl;

class YoshiGenerator extends GeneratorForAnnotation<YoshiService> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final annotation = _annotationsProcessor.getClassAnnotation(element);

    _baseUrl = annotation?.peek('baseUrl')?.stringValue;
    try {
      return DartFormatter().format(_generateClass(element) +
          _generateImplClass(element).replaceFirst('class', 'mixin'));
    } catch (e) {
      return "/*$e*/";
    }
  }
}

String _generateClass(ClassElement element) {
  final serviceClass = Class(
    (c) => c
      ..name = '${element.displayName}Service'
      ..extend = refer(element.displayName)
      ..mixins.add(refer('_\$${element.name}'))
      ..constructors.add(Constructor(//UnnamedConstructor
          (cons) => cons..body = Code('_client = YoshiClient();')))
      ..constructors.add(Constructor(
          (cons) => cons // factory constructor for providing own client.
            ..name = 'withClient'
            ..requiredParameters.add(Parameter((p) => p
              ..name = 'client'
              ..type = refer('YoshiClient')))
            ..body = Code('_client = client;')
            ..build())),
  );
  final emitter = DartEmitter();
  return _dartFmt.format('${serviceClass.accept(emitter)}');
}

String _generateImplClass(ClassElement element) {
  final yoshi = Class((c) => c
    ..name = '_\$${element.name}'
    ..implements.add(refer(element.name))
    ..fields.add(Field((f) => f
      ..name = '_client'
      ..type = refer('YoshiClient')))
    ..methods.addAll(_parseMethods(element.methods))
    ..build());
  final emitter = DartEmitter();
  return _dartFmt.format('${yoshi.accept(emitter)}');
}

Iterable<Method> _parseMethods(List<MethodElement> methodElements) =>
    methodElements
        .where((m) => m.isAbstract && m.metadata.isNotEmpty)
        .map(_parseMethod);

Method _parseMethod(MethodElement element) => Method((b) => b
  ..name = element.name
  ..returns = Reference(element.returnType.displayName)
  ..modifier = MethodModifier.async
  ..annotations.add(refer('override'))
  ..requiredParameters.addAll(_parseRequiredParameters(element.parameters))
  ..optionalParameters.addAll(_parseOptionalParameters(element.parameters))
  ..body = _parseBody(element)
  ..build());

Code _parseBody(MethodElement element) {
  final _methodAnnotation = _annotationsProcessor.getMethodAnnotations(element);
  final paramSources = element.parameters
      .map(_annotationsProcessor.getParameterAnnotations)
      .map((reader) => reader.isEmpty ? null : reader.first?.revive()?.source);

  print(paramSources);

  Type methodType = _annotationsProcessor.getMethodType(element);

  String url = 'adfad';
  String method = 'post';

  if (methodType == Get) {
    method = 'get';
  } else if (methodType == Post) {
    method = 'post';
  }

  url = path.url.join(
      "\${_client.baseUrl}",
      _baseUrl ?? "",
      _methodAnnotation
          .firstWhere((annotation) => annotation.type == methodType,
              orElse: () => null)
          ?.reader
          ?.peek('url')
          ?.stringValue);

  final bodyParams = _annotationsProcessor.getMethodAnnotation(element, Body);

  final pathParams = _annotationsProcessor.getMethodAnnotation(element, Path);

  final queryParams = _annotationsProcessor.getMethodAnnotation(element, Query);

  pathParams.forEach((p) {
    final pathId = p.reader.peek('path')?.stringValue;
    final pathParam = p.element.name;

    url = url.replaceAll('{$pathId}', '\$$pathParam');
  });

  String queryString = queryParams.map((p) {
    final queryId = p.reader.peek('query')?.stringValue;
    final queryParam = p.element.name;
    return '$queryId=\$$queryParam';
  }).join('&');

  if (queryString != '') {
    url += '?$queryString';
  }

  if (bodyParams.length > 1) {}
  final bodyParam = bodyParams.isEmpty ? null : bodyParams?.first?.element;
  if (bodyParam != null &&
      !bodyParam.type.isDartCoreMap &&
      !bodyParam.type.isDartCoreString) {
    final ClassElement bodyClassElement = bodyParam.type.element;

    final toJsonElement =
        bodyClassElement.lookUpConcreteMethod('toJson', bodyParam.library);

    if (toJsonElement == null) {
      throw InvalidGenerationSourceError(
          'Class ${bodyClassElement.displayName} must implement '
          'method toJson to convert ${bodyClassElement.displayName} object into map data');
    }
  }

  final sb = StringBuffer();

  final _typeArgs = typeArgs(element.returnType);

  if (_typeArgs.length > 4) {
    throw InvalidGenerationSourceError(
        "Only upto 4 levels of depth in the return type of a call is supported.. \ne.g., Future<Call<List<List<T>>>> is not supported");
  }

  final bool doesReturnCall =
      callTypeChecker.isAssignableFromType(_typeArgs.elementAt(1));

  if (!doesReturnCall) {
    throw InvalidGenerationSourceError(
        'Should return Call ---- \n\n $_typeArgs');
  }

  final _retType = _typeArgs.elementAt(2);
  final type = _typeArgs.last;
  final needDeserialization = needsDeserialization(type);

  if (needDeserialization) {
    final fromJsonElement =
        (type.element as ClassElement)?.getNamedConstructor('fromJson') ??
            (type.element as ClassElement)
                .lookUpConcreteMethod('fromJson', type.element.library);

    if (fromJsonElement == null) {
      throw InvalidGenerationSourceError(
          'Class ${type.element.name} must implement factory or '
          'static method fromJson to convert map data into ${type.element.name} object');
    }
  }

  if (coreIterableTypeChecker.isAssignableFromType(_retType)) {
    var data = '(json.decode(res.body) as List)';

    if (!type.isDynamic) {
      data = "$data.map((it) => $type.fromJson(it))";
    }

    if (_retType.isDartCoreList) {
      data = "$data.toList()";
    } else if (_retType.isDartCoreSet) {
      data = "$data.toSet()";
    }

    sb.write('''
final res = await _client.$method(\'$url\');
return ${_typeArgs.elementAt(1)}(
    data: $data,
    statusCode: res.statusCode,
    reasonPhrase: res.reasonPhrase,
    headers: HttpHeaders.fromMap(res.headers),
  );
''');
  } else {
    var data = 'json.decode(res.body)';
    if (!type.isDynamic) data = '$type.fromJson($data)';

    sb.write('''
final res = await _client.$method(\'$url\');
return ${_typeArgs.elementAt(1)}(
    data: $data,
    statusCode: res.statusCode,
    reasonPhrase: res.reasonPhrase,
    headers: HttpHeaders.fromMap(res.headers),
  );
''');
  }

  // if (coreIterableTypeChecker.isAssignableFromType(_retType)) {
  //   sb.write('return (await _client.$method(\'$url\') as List)');

  //   if (needDeserialization) {
  //     sb.write('.map((m) => $type.fromJson(m)).toList();');
  //   } else {
  //     sb.write(';');
  //   }
  // } else {
  //   if (_retType.isDartCoreString || _retType.isDynamic || _retType.isObject) {
  //     sb.write(' return await _client.$method(\'$url\');');
  //   } else {
  //     if (needDeserialization) {
  //       if (method == "post" && bodyParam != null) {
  //         final body = needsSerialization(bodyParam.type)
  //             ? "json.encode(${bodyParam.displayName}${bodyParam.type.isDartCoreMap ? "" : ".toJson()"})"
  //             : "${bodyParam.displayName}";
  //         sb.write(
  //             'return $type.fromJson(await _client.$method(\'$url\', body: $body) as Map);');
  //       } else {
  //         sb.write('''
  //         final res = await _client.$method(\'$url\');
  //         return Call(
  //             data: json.decode(res.body),
  //             statusCode: res.statusCode,
  //             reasonPhrase: res.reasonPhrase,
  //             headers: HttpHeaders.fromMap(res.headers),
  //           );
  //         ''');
  //       }
  //     } else {
  //       if (method == "post" && bodyParam != null) {
  //         final body = needsSerialization(bodyParam.type)
  //             ? "json.encode(${bodyParam.displayName}${bodyParam.type.isDartCoreMap ? "" : ".toJson()"})"
  //             : "${bodyParam.displayName}";
  //         sb.write('''
  //         final res = await _client.$method(\'$url\', body: $body);
  //         return Call(
  //             data: json.decode(res.body),
  //             statusCode: res.statusCode,
  //             reasonPhrase: res.reasonPhrase,
  //             headers: HttpHeaders.fromMap(res.headers),
  //           );
  //         ''');
  //       } else {
  //         sb.write('''
  //         final res = await _client.$method(\'$url\');
  //         return Call(
  //             data: json.decode(res.body),
  //             statusCode: res.statusCode,
  //             reasonPhrase: res.reasonPhrase,
  //             headers: HttpHeaders.fromMap(res.headers),
  //           );
  //         ''');
  //       }
  //     }
  // }
  // }

  return Code(sb.toString());
}

Iterable<Parameter> _parseRequiredParameters(
        List<ParameterElement> parameters) =>
    parameters
        .where((parameter) => parameter.isNotOptional)
        .map(_parseParameter);

Iterable<Parameter> _parseOptionalParameters(
        List<ParameterElement> parameters) =>
    parameters.where((parameter) => parameter.isOptional).map(_parseParameter);

Parameter _parseParameter(ParameterElement param) => Parameter((p) {
      return p
        ..name = param.name
        ..type = refer(param.type.name);
    });
