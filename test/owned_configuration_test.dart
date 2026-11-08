import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spotiflac/services/app_remote_config_service.dart';
import 'package:spotiflac/services/discord_presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unconfigured funding has no payment destination', () {
    final config = DonateConfig.fallback();
    expect(config.enabled, isFalse);
    expect(config.methods, isEmpty);
    expect(config.supporters, isEmpty);
  });

  test('disabling remote config performs no request', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    final service = AppRemoteConfigService(endpoint: '', client: client);
    expect(await service.fetchConfigSnapshot(), isNull);
    expect(await service.readCachedConfig(), isNull);
    expect(requests, 0);
    client.close();
  });

  test('unconfigured Discord does not initialize a native account', () async {
    const channel = MethodChannel('test/owned-discord');
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          calls++;
          return true;
        });
    final service = DiscordPresenceService(
      channel: channel,
      integrationEnabled: false,
    );
    await service.setEnabled(true);
    expect(service.status.value, DiscordPresenceStatus.sdkUnavailable);
    expect(calls, 0);
    await service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
