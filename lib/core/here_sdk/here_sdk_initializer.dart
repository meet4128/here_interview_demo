import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';

class HereSdkInitializationException implements Exception {
  final String message;
  final Object? cause;

  const HereSdkInitializationException(this.message, [this.cause]);

  @override
  String toString() =>
      'HereSdkInitializationException: $message'
          '${cause != null ? ' (cause: $cause)' : ''}';
}

/// HERE SDK's native engine lifecycle.
class HereSdkInitializer {
  HereSdkInitializer._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initializes the HERE SDK's native engine with the given credentials.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    SdkContext.init(IsolateOrigin.main);

    final authenticationMode = AuthenticationMode.withKeySecret(
      "9lT00Ipx_YMeDeGCAb_I8w",
      "qGZHGcdoFIIZ2Y0MjiBfiCW4qiqsnEVOXgUfPpb2qnlEERbNnIGz6KK1l6x-AtUS593qPHJ7vWzjCnOLHqOYPw",
    );
    final sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

    try {
      await SDKNativeEngine.makeSharedInstance(sdkOptions);
      _isInitialized = true;
    } on InstantiationException catch (e) {
      throw HereSdkInitializationException(
        'Failed to initialize the HERE SDK',
        e,
      );
    }
  }

  /// Releases the HERE SDK's native resources.
  static Future<void> dispose() async {
    if (!_isInitialized) return;
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    _isInitialized = false;
  }
}