import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, UserEntity?>> authenticateUser(
    String username,
    String password,
  );
  Future<Either<Failure, UserEntity>> getUserById(String id);
  Future<Either<Failure, UserEntity?>> getUserByUsername(String username);
  Future<Either<Failure, List<UserEntity>>> getAllUsers({
    PaginationParams? params,
  });
  Future<Either<Failure, UserEntity>> createUser(UserEntity user);
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);
  Future<Either<Failure, void>> deleteUser(String id);
  Future<Either<Failure, bool>> isUsernameExists(
    String username, {
    String? excludeId,
  });
  Future<Either<Failure, bool>> isEmailExists(
    String email, {
    String? excludeId,
  });
  Future<Either<Failure, void>> updateLastLogin(
    String userId,
    DateTime lastLoginAt,
  );
  Future<Either<Failure, void>> changePassword(
    String userId,
    String newPassword,
  );
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query);
  Future<Either<Failure, int>> getUserCount();
  Future<Either<Failure, List<UserEntity>>> getUsersByRole(UserRole role);
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool isActive);
  Stream<Either<Failure, List<UserEntity>>> watchUsers();
  Stream<Either<Failure, UserEntity?>> watchUser(String id);
}
