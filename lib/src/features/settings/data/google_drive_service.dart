import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final googleDriveProvider = Provider((ref) => GoogleDriveService());

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;

  // 1. Sign In
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  // 2. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
  }

  // 3. Upload File to Drive
  Future<bool> uploadBackup(File file) async {
    if (_currentUser == null) await signIn();
    if (_currentUser == null) return false; // Failed to sign in

    try {
      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      // File Metadata
      var driveFile = drive.File();
      driveFile.name = "MyKhata_Backup_${DateTime.now().toIso8601String()}.json";
      driveFile.parents = ["appDataFolder"]; // Hidden folder for app data

      // Upload
      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );
      
      return true;
    } catch (e) {
      print("Upload Error: $e");
      return false;
    }
  }
}