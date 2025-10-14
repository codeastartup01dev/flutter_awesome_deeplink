import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_awesome_deeplink_method_channel.dart';

abstract class FlutterAwesomeDeeplinkPlatform extends PlatformInterface {
  /// Constructs a FlutterAwesomeDeeplinkPlatform.
  FlutterAwesomeDeeplinkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAwesomeDeeplinkPlatform _instance = MethodChannelFlutterAwesomeDeeplink();

  /// The default instance of [FlutterAwesomeDeeplinkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAwesomeDeeplink].
  static FlutterAwesomeDeeplinkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAwesomeDeeplinkPlatform] when
  /// they register themselves.
  static set instance(FlutterAwesomeDeeplinkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
