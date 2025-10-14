import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_awesome_deeplink_platform_interface.dart';

/// An implementation of [FlutterAwesomeDeeplinkPlatform] that uses method channels.
class MethodChannelFlutterAwesomeDeeplink extends FlutterAwesomeDeeplinkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_awesome_deeplink');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
