import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anidong/services/ad_service.dart';
import 'dart:io';

void main() {
  group('Platform Check Tests', () {
    test('AdService should not initialize on non-mobile platforms', () async {
      final adService = AdService.instance;

      // Ensure that calling initialize on non-mobile doesn't throw and behaves as expected
      // Since we are in a test environment (usually Linux), it should skip initialization
      await adService.initialize();

      // The internal showAdIfAvailable should just call onComplete immediately
      bool called = false;
      adService.showAdIfAvailable(() {
        called = true;
      });

      expect(called, isTrue);
    });

    test('Current test environment platform identification', () {
      // In CI, this is likely Linux
      debugPrint('Running on platform: ${Platform.operatingSystem}');
      expect(Platform.isWindows || Platform.isLinux || Platform.isMacOS, isTrue);
    });
  });
}
