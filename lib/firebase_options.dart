// File generated manually from GoogleService-Info.plist and google-services.json
// DO NOT COMMIT — contains API keys

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web platform not supported for FCM');
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRFxvpAYVhCLH1JxHHE6UL_2PQviMza-k',
    appId: '1:653196752986:ios:b1cb1cf3a5eea6d71fc063',
    messagingSenderId: '653196752986',
    projectId: 'fieldly-c1e95',
    storageBucket: 'fieldly-c1e95.firebasestorage.app',
    iosBundleId: 'com.example.frontendPim',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKWb8fVxNstab3GOeU17xVFxpeSjwwFWM',
    appId: '1:653196752986:android:ebaab9ac2bb336771fc063',
    messagingSenderId: '653196752986',
    projectId: 'fieldly-c1e95',
    storageBucket: 'fieldly-c1e95.firebasestorage.app',
  );
}
