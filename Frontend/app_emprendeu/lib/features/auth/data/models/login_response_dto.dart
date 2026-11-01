import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_session.dart';
import 'auth_user_dto.dart';

part 'login_response_dto.freezed.dart';
part 'login_response_dto.g.dart';

@freezed
abstract class LoginResponseDto with _$LoginResponseDto {
  const LoginResponseDto._();

  const factory LoginResponseDto({
    @JsonKey(name: 'access_token') required String accessToken,
    required AuthUserDto user,
  }) = _LoginResponseDto;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  AuthSession toEntity() =>
      AuthSession(accessToken: accessToken, user: user.toEntity());
}
