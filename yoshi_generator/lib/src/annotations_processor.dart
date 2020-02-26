import 'package:yoshi/yoshi.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';

@immutable
class AnnotatedParam {
  final ParameterElement element;
  final ConstantReader reader;
  const AnnotatedParam(this.element, this.reader);
}

@immutable
class AnnotationElement {
  final Type type;
  final ConstantReader reader;
  const AnnotationElement(this.type, this.reader);
}

class AnnotationsProcessor {
  TypeChecker _typeChecker(Type t) => TypeChecker.fromRuntime(t);

  final _methodAnnotations = [
    Get,
    Post,
    Head,
    Put,
    Delete,
  ];

  final _parameterTypeAnnotations = [Body, Query, Path];

  ConstantReader getClassAnnotation(ClassElement element) {
    final annotation =
        _typeChecker(YoshiService).firstAnnotationOf(element);
    return annotation != null ? ConstantReader(annotation) : null;
  }

  List<AnnotatedParam> getMethodAnnotation(MethodElement element, Type type) => element.parameters.map((param) {
      var annot;
      ParameterElement parameter;
      final a = _typeChecker(type).firstAnnotationOfExact(param);
      if (annot != null && a != null) {
        throw Exception(
            "Too many $type annotations for '${element.displayName}");
      } else if (annot == null && a != null) {
        annot = a;
        parameter = param;
      }
      return AnnotatedParam(parameter, annot == null ? null : ConstantReader(annot));
    }).where((annotation) => annotation.reader != null).toList();

  Type getMethodType(element) {
    return _methodAnnotations.firstWhere((annotation) {
      return _typeChecker(annotation).hasAnnotationOfExact(element);
    }, orElse: () => null);
  }

  List<AnnotationElement> getMethodAnnotations(MethodElement element) =>
      (_methodAnnotations..add(Headers))
          .map((annotation) {
            final annot =
                _typeChecker(annotation).firstAnnotationOfExact(element);
            return annot != null
                ? AnnotationElement(annotation, ConstantReader(annot))
                : null;
          })
          .where((annotation) =>
              annotation != null &&
              element.isAbstract &&
              element.returnType.isDartAsyncFuture)
          .toList();

  List<ConstantReader> getParameterAnnotations(ParameterElement element) {
    final annots = _parameterTypeAnnotations
        .map((annotation) {
          final annot = _typeChecker(annotation).annotationsOf(element);
          return annot.isEmpty ? annot : null;
        })
        .where((annotation) => annotation != null)
        .expand((f) => f)
        .map((f) => ConstantReader(f))
        .toList();

    if (_parameterTypeAnnotations.any(
        (p) => annots.where((e) => e.instanceOf(_typeChecker(p))).length > 1)) {
      throw InvalidGenerationSourceError(
          'More than 1 method annotations of the same kind');
    }

    return annots;
  }
}
