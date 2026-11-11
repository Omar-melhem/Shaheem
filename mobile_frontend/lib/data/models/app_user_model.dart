// Data-layer (API) representation of the current user.

import 'package:mobile_frontend/domain/entities/app_user.dart';
import 'package:mobile_frontend/domain/errors/auth_exceptions.dart';

/// Raw current-user data as received from the backend.
///
/// BACKEND PENDING: JSON parsing (`fromJson`) is not written yet because the
/// API schema and field names are not defined. Every field is nullable here
/// so an incomplete payload can be detected instead of crashing.
class AppUserModel {
  const AppUserModel({this.id, this.displayName, this.phone, this.role});

  final String? id;
  final String? displayName;
  final String? phone;
  final String? role;

  /// Converts to the domain [AppUser].
  ///
  /// Throws [InvalidProfileException] when the identifier is missing or
  /// blank, so the app never continues with an unidentifiable user.
  AppUser toEntity() {
    final userId = id?.trim();
    if (userId == null || userId.isEmpty) {
      throw const InvalidProfileException();
    }
    return AppUser(
      id: userId,
      displayName: displayName,
      phone: phone,
      role: role,
    );
  }
}
