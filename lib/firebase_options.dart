import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw StateError(
      'Configure Firebase for this company before enabling push.');
}
