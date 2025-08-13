import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}

class PaginationParams extends Equatable {
  final int page;
  final int limit;
  final String? searchQuery;
  final Map<String, dynamic>? filters;
  final String? sortBy;
  final bool ascending;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.searchQuery,
    this.filters,
    this.sortBy,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [
    page,
    limit,
    searchQuery,
    filters,
    sortBy,
    ascending,
  ];

  PaginationParams copyWith({
    int? page,
    int? limit,
    String? searchQuery,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? ascending,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

class IdParams extends Equatable {
  final String id;

  const IdParams({required this.id});

  @override
  List<Object> get props => [id];
}

class IdsParams extends Equatable {
  final List<String> ids;

  const IdsParams({required this.ids});

  @override
  List<Object> get props => [ids];
}

class DateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeParams({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

class SearchParams extends Equatable {
  final String query;
  final Map<String, dynamic>? filters;
  final int? limit;

  const SearchParams({required this.query, this.filters, this.limit});

  @override
  List<Object?> get props => [query, filters, limit];
}
