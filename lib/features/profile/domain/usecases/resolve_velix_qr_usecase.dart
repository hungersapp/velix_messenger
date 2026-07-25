import '../../../authentication/data/datasources/velix_user_remote_datasource.dart';
import '../entities/velix_public_profile.dart';
import '../exceptions/velix_qr_exceptions.dart';
import '../services/velix_qr_payload.dart';

/// Validates a scanned QR payload and resolves the matching Firestore user.
class ResolveVelixQrUseCase {
  const ResolveVelixQrUseCase(this._userDatasource);

  final VelixUserRemoteDatasource _userDatasource;

  Future<VelixPublicProfile> call(String rawPayload) async {
    final velixId = VelixQrPayload.tryParseVelixId(rawPayload);
    if (velixId == null) {
      throw InvalidVelixQrException();
    }

    final data = await _userDatasource.findByVelixId(velixId);
    if (data == null) {
      throw VelixUserNotFoundException();
    }

    final profile = VelixPublicProfile.fromFirestore(data);
    if (profile.uid.isEmpty || profile.velixId.isEmpty) {
      throw VelixUserNotFoundException();
    }

    return profile;
  }
}
