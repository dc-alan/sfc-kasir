import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

typedef Result<T> = Either<Failure, T>;

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => isRight();
  bool get isFailure => isLeft();

  T? get data => fold((l) => null, (r) => r);
  Failure? get failure => fold((l) => l, (r) => null);

  Result<U> map<U>(U Function(T) mapper) {
    return fold((failure) => Left(failure), (data) => Right(mapper(data)));
  }

  Future<Result<U>> mapAsync<U>(Future<U> Function(T) mapper) async {
    return fold(
      (failure) => Left(failure),
      (data) async => Right(await mapper(data)),
    );
  }

  Result<U> flatMap<U>(Result<U> Function(T) mapper) {
    return fold((failure) => Left(failure), (data) => mapper(data));
  }

  Future<Result<U>> flatMapAsync<U>(
    Future<Result<U>> Function(T) mapper,
  ) async {
    return fold((failure) => Left(failure), (data) => mapper(data));
  }

  void when({
    required void Function(T data) onSuccess,
    required void Function(Failure failure) onFailure,
  }) {
    fold(onFailure, onSuccess);
  }

  Future<void> whenAsync({
    required Future<void> Function(T data) onSuccess,
    required Future<void> Function(Failure failure) onFailure,
  }) async {
    await fold(onFailure, onSuccess);
  }
}

class ResultUtils {
  static Result<T> success<T>(T data) => Right(data);

  static Result<T> failure<T>(Failure failure) => Left(failure);

  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final List<T> successResults = [];

    for (final result in results) {
      if (result.isFailure) {
        return Left(result.failure!);
      }
      successResults.add(result.data as T);
    }

    return Right(successResults);
  }

  static Future<Result<List<T>>> combineAsync<T>(
    List<Future<Result<T>>> futures,
  ) async {
    final List<T> successResults = [];

    for (final future in futures) {
      final result = await future;
      if (result.isFailure) {
        return Left(result.failure!);
      }
      successResults.add(result.data as T);
    }

    return Right(successResults);
  }

  static Result<T> fromNullable<T>(T? value, Failure Function() onNull) {
    return value != null ? Right(value) : Left(onNull());
  }

  static Result<T> tryCatch<T>(
    T Function() operation,
    Failure Function(Exception exception) onError,
  ) {
    try {
      return Right(operation());
    } on Exception catch (e) {
      return Left(onError(e));
    }
  }

  static Future<Result<T>> tryCatchAsync<T>(
    Future<T> Function() operation,
    Failure Function(Exception exception) onError,
  ) async {
    try {
      final result = await operation();
      return Right(result);
    } on Exception catch (e) {
      return Left(onError(e));
    }
  }
}
