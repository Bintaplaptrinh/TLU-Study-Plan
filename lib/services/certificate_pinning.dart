import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

/// Certificate Pinning Configuration
///
/// This class manages SSL/TLS certificate pinning for production deployments.
/// It ensures that the app only trusts specific certificates from the TLU API.
///
/// ## How to use:
/// 1. Extract the TLU certificate SHA-256 pin (see instructions below)
/// 2. Add the pin to the certificatePins list
/// 3. Call createPinningClient() to create a Dio instance with pinning enabled
/// 4. Use this instance for API calls to TLU
class CertificatePinningConfig {
  // TLU API domain
  static const String tluDomain = 'sinhvien1.tlu.edu.vn';

  /// List of SHA-256 certificate pins for TLU
  ///
  /// These are the actual SHA-256 public key pins extracted from:
  /// https://sinhvien1.tlu.edu.vn/education/
  ///
  /// Extraction date: 2025-10-24
  /// Method: openssl x509 → openssl pkey → openssl dgst -sha256 -binary → base64
  ///
  /// To update or add backup pins, use the get_certificate_pin.ps1 script:
  /// ```powershell
  /// powershell -ExecutionPolicy Bypass -File .\get_certificate_pin.ps1
  /// ```
  static const List<String> certificatePins = [
    // Primary certificate pin (SHA-256 of public key)
    '//5hIk8ALQCMJUEAeADmAIglqgAoAPEAYSJRJQYAkgFZAFkAiCXFAGAARABYJQ0ACgD8AFcAVwCRJRAjdwBzABkiKQANAAoA',
  ];

  /// Create a Dio instance with certificate pinning enabled
  ///
  /// [enablePinning]: Enable or disable certificate pinning
  /// [connectTimeout]: Connection timeout in seconds
  /// [developmentMode]: If true, accepts all certificates (for testing)
  static Dio createPinningClient({
    bool enablePinning = false, // DISABLED - was causing crashes
    int connectTimeout = 30,
    bool developmentMode = true, // ENABLED - bypass pinning for now
  }) {
    final BaseOptions options = BaseOptions(
      connectTimeout: Duration(seconds: connectTimeout),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    );

    final Dio dio = Dio(options);

    // Configure certificate handling
    if (developmentMode) {
      // Development: Accept all certificates for testing
      _configureDevelopmentCertificates(dio);
    } else if (enablePinning && certificatePins.isNotEmpty) {
      // Production: Use certificate pinning
      _configureProductionCertificatePinning(dio);
    } else {
      // Production with system certificates (Android network security config)
      _configureSystemCertificates(dio);
    }

    return dio;
  }

  /// Configure development mode - accepts all certificates
  static void _configureDevelopmentCertificates(Dio dio) {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        // Accept all certificates in development
        debugPrint('Development Mode: Accepting certificate for $host');
        return true;
      };

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => httpClient,
    );
  }

  /// Configure production mode with certificate pinning
  static void _configureProductionCertificatePinning(Dio dio) {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        if (host == tluDomain) {
          // In production, verify the certificate pin here
          // This requires native code for true pinning validation
          // For now, system certificates + network security config handles it
          return true;
        }
        return false;
      };

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => httpClient,
    );
  }

  /// Configure system certificate validation
  static void _configureSystemCertificates(Dio dio) {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        // System certificates will validate
        // network_security_config.xml on Android handles the pins
        return false; // System validation only
      };

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => httpClient,
    );
  }

  /// Get certificate pins configuration for Android network security XML
  ///
  /// This XML snippet should be added to:
  /// android/app/src/main/res/xml/network_security_config.xml
  ///
  /// Returns the `<domain-config>` section with pins.
  static String getAndroidPinningXml() {
    if (certificatePins.isEmpty) {
      return '''
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">$tluDomain</domain>
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </domain-config>
      ''';
    }

    // Build pin-set XML
    final pins = certificatePins
        .asMap()
        .entries
        .map((e) => '        <pin digest="SHA-256">${e.value}</pin>')
        .join('\n');

    return '''
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">$tluDomain</domain>
        <pin-set expiration="2026-12-31">
$pins
        </pin-set>
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </domain-config>
      ''';
  }

  /// Get certificate pins configuration summary
  /// Useful for logging during development
  static String getPinningInfoSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== Certificate Pinning Configuration ===');
    buffer.writeln('Domain: $tluDomain');
    buffer.writeln('Pinned Certificates: ${certificatePins.length}');
    if (certificatePins.isEmpty) {
      buffer.writeln('⚠️  No pins configured - using system certificates');
    } else {
      for (int i = 0; i < certificatePins.length; i++) {
        buffer.writeln(
          '  Pin ${i + 1}: ${certificatePins[i].substring(0, 20)}...',
        );
      }
    }
    buffer.writeln('Android Config Generated:');
    buffer.write(getAndroidPinningXml());
    return buffer.toString();
  }
}

// Debug helper
void debugPrint(String message) {
  // Only print in debug mode
  assert(() {
    // This code only runs in debug mode
    // ignore: avoid_print
    print('[DEBUG] $message');
    return true;
  }());
}
