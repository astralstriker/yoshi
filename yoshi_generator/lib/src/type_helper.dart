import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yoshi/yoshi.dart';

const coreIterableTypeChecker = TypeChecker.fromUrl('dart:core#Iterable');
const coreMapTypeChecker = TypeChecker.fromUrl('dart:core#Map');
const rxObservableChecker =
    TypeChecker.fromUrl('package:rxdart/rxdart.dart#Observable');
const callTypeChecker =
    TypeChecker.fromRuntime(Call);

List<DartType> typeArgumentsOf(DartType type, TypeChecker checker) {
  final implementation = _getImplementationType(type, checker) as InterfaceType;
  return implementation?.typeArguments;
}

bool needsDeserialization(DartType type) {
  return !type.isDynamic &&
      !type.isDartCoreObject &&
      !type.isDartCoreString &&
      !type.isDartCoreMap &&
      !type.isDartCoreInt &&
      !type.isDartCoreBool &&
      !type.isDartCoreDouble &&
      !type.isDartAsyncFuture &&
      !callTypeChecker.isAssignableFromType(type) &&
      !rxObservableChecker.isAssignableFromType(type) &&
      !coreIterableTypeChecker.isAssignableFromType(type) &&
      !coreMapTypeChecker.isAssignableFromType(type);
}

bool needsSerialization(DartType type) {
  return !type.isDartCoreString;
}

Iterable<DartType> typeArgs(DartType type) sync* {
  yield type;
  if (type is InterfaceType) {
    yield* type.typeArguments.expand(typeArgs);
  }
}

DartType _getImplementationType(DartType type, TypeChecker checker) =>
    typeArgs(type).firstWhere(checker.isExactlyType, orElse: () => null);
