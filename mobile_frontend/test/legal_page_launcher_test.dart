// Tests for in-app-only legal page opening: URL trust, platform gating,
// failure handling without any fallback, and the url_launcher adapter's
// exact request (in-app web view only, JavaScript and DOM storage off).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/helper/legal/legal_links.dart';
import 'package:mobile_frontend/helper/legal/legal_page_launcher.dart';

import 'fakes.dart';

/// A syntactically valid HTTPS address used only inside tests; never
/// configured in the app.
const _testUrl = 'https://legal.test.invalid/terms-test';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LegalPageLauncher subject(
    FakeInAppWebPageLauncher fake, {
    String url = _testUrl,
    TargetPlatform platform = TargetPlatform.android,
  }) => LegalPageLauncher(launcher: fake, termsUrl: url, platform: platform);

  test('the Terms URL is not provided yet (no invented address)', () {
    expect(LegalLinks.termsAndConditions, isEmpty);
  });

  test(
    'not configured → notConfigured; nothing is checked or opened',
    () async {
      final fake = FakeInAppWebPageLauncher();
      expect(
        await subject(fake, url: '').openTermsAndConditions(),
        LegalPageOpenResult.notConfigured,
      );
      expect(fake.supportChecks, 0);
      expect(fake.opened, isEmpty);
      // The default launcher reads the central (empty) configuration.
      expect(
        await const LegalPageLauncher().openTermsAndConditions(),
        LegalPageOpenResult.notConfigured,
      );
    },
  );

  group('untrusted values are never opened', () {
    for (final raw in [
      'http://legal.test.invalid/terms',
      'javascript:alert(1)',
      'file:///etc/hosts',
      'intent://legal#Intent;scheme=https;end',
      'data:text/html,<p>x</p>',
      'ftp://legal.test.invalid/terms',
      'https://',
      'https:///terms',
      '/terms',
      'legal.test.invalid/terms',
      'https://user:secret@legal.test.invalid/terms',
      ' https://legal.test.invalid/terms',
      'HTTPS//legal.test.invalid',
    ]) {
      test('"$raw" → invalidUrl', () async {
        final fake = FakeInAppWebPageLauncher();
        expect(
          await subject(fake, url: raw).openTermsAndConditions(),
          LegalPageOpenResult.invalidUrl,
        );
        expect(fake.opened, isEmpty);
      });
    }

    test('an uppercase HTTPS scheme is normalized by Uri and accepted', () {
      expect(
        LegalPageLauncher.trustedHttpsUri('HTTPS://legal.test.invalid/t'),
        isNotNull,
      );
    });
  });

  group('platform gating (no fallback)', () {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      test('${platform.name} → unsupported, nothing opened', () async {
        final fake = FakeInAppWebPageLauncher();
        expect(
          await subject(fake, platform: platform).openTermsAndConditions(),
          LegalPageOpenResult.unsupported,
        );
        expect(fake.supportChecks, 0);
        expect(fake.opened, isEmpty);
      });
    }

    test('in-app mode not supported → unsupported, never opened', () async {
      final fake = FakeInAppWebPageLauncher(supports: false);
      expect(
        await subject(fake).openTermsAndConditions(),
        LegalPageOpenResult.unsupported,
      );
      expect(fake.supportChecks, 1);
      expect(fake.opened, isEmpty);
    });
  });

  group('opening', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('${platform.name}: opens the exact URL once, in-app', () async {
        final fake = FakeInAppWebPageLauncher();
        expect(
          await subject(fake, platform: platform).openTermsAndConditions(),
          LegalPageOpenResult.opened,
        );
        expect(fake.opened, [Uri.parse(_testUrl)]);
      });
    }

    test('presentation refused → failed after a single attempt', () async {
      final fake = FakeInAppWebPageLauncher(opens: false);
      expect(
        await subject(fake).openTermsAndConditions(),
        LegalPageOpenResult.failed,
      );
      expect(fake.opened, hasLength(1));
    });

    test('platform error → failed after a single attempt', () async {
      final fake = FakeInAppWebPageLauncher()
        ..error = PlatformException(code: 'ACTIVITY_NOT_FOUND');
      expect(
        await subject(fake).openTermsAndConditions(),
        LegalPageOpenResult.failed,
      );
      expect(fake.opened, hasLength(1));
    });
  });

  group('url_launcher adapter', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'requests only the in-app web view, JavaScript and storage off',
      () async {
        final ok = await const UrlLauncherInAppWebPageLauncher()
            .openInAppWebView(Uri.parse(_testUrl));
        expect(ok, isTrue);
        expect(calls, hasLength(1));
        expect(calls.single.method, 'launch');
        final args = Map<String, Object?>.from(calls.single.arguments as Map);
        expect(args['url'], _testUrl);
        expect(args['useWebView'], isTrue);
        expect(args['useSafariVC'], isTrue);
        expect(args['enableJavaScript'], isFalse);
        expect(args['enableDomStorage'], isFalse);
        expect(args['universalLinksOnly'], isFalse);
      },
    );

    test(
      'a platform that cannot confirm in-app support opens nothing',
      () async {
        // The generic platform implementation reports only platformDefault as
        // supported, so the real launcher must stop instead of falling back.
        const real = LegalPageLauncher(
          termsUrl: _testUrl,
          platform: TargetPlatform.android,
        );
        expect(
          await real.openTermsAndConditions(),
          LegalPageOpenResult.unsupported,
        );
        expect(calls, isEmpty);
      },
    );
  });
}
