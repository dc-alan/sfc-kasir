import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_entity.dart';
import '../../repositories/user_repository.dart';

class GetAllUsers implements UseCase<List<UserEntity>, PaginationParams> {
  final UserRepository repository;

  GetAllUsers(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(
    PaginationParams params,
  ) async {
    return await repository.getAllUsers(params: params);
  }
}
