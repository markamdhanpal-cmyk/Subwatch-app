import 'package:flutter/material.dart';

/// Brand-colored lettermark entry for a known subscription service.
class ServiceIconEntry {
  const ServiceIconEntry({
    required this.glyph,
    required this.brandColor,
    this.glyphColor = const Color(0xFFF7ECDD),
  });

  /// Single character displayed inside the avatar.
  final String glyph;

  /// Primary brand color used as the avatar background gradient base.
  final Color brandColor;

  /// Color for the glyph text. Defaults to light ink for dark backgrounds.
  final Color glyphColor;
}

/// Registry mapping known service keys to brand-colored lettermarks.
///
/// Call [lookup] with a service key string to get a [ServiceIconEntry] if the
/// service is recognized. Returns `null` for unrecognized services, allowing
/// callers to fall back to the existing monogram system.
class ServiceIconRegistry {
  const ServiceIconRegistry._();

  static const Map<String, ServiceIconEntry> _entries =
      <String, ServiceIconEntry>{
    'NETFLIX': ServiceIconEntry(
      glyph: 'N',
      brandColor: Color(0xFFB20710),
    ),
    'SPOTIFY': ServiceIconEntry(
      glyph: 'S',
      brandColor: Color(0xFF1A7A3A),
    ),
    'AMAZON_PRIME': ServiceIconEntry(
      glyph: 'P',
      brandColor: Color(0xFF00627A),
    ),
    'YOUTUBE_PREMIUM': ServiceIconEntry(
      glyph: 'Y',
      brandColor: Color(0xFFAA0000),
    ),
    'JIOHOTSTAR': ServiceIconEntry(
      glyph: 'H',
      brandColor: Color(0xFF0C3153),
    ),
    'GOOGLE_PLAY': ServiceIconEntry(
      glyph: 'G',
      brandColor: Color(0xFF1E7E40),
    ),
    'GOOGLE_ONE': ServiceIconEntry(
      glyph: '1',
      brandColor: Color(0xFF2A62B0),
    ),
    'GOOGLE_GEMINI_PRO': ServiceIconEntry(
      glyph: 'G',
      brandColor: Color(0xFF2A62B0),
    ),
    'ADOBE_SYSTEMS': ServiceIconEntry(
      glyph: 'A',
      brandColor: Color(0xFFAA0000),
    ),
    'APPLE_SERVICES': ServiceIconEntry(
      glyph: 'A',
      brandColor: Color(0xFF3A3F42),
      glyphColor: Color(0xFFD0D5D8),
    ),
    'CHATGPT': ServiceIconEntry(
      glyph: 'C',
      brandColor: Color(0xFF0B7A5F),
    ),
    'CANVA': ServiceIconEntry(
      glyph: 'C',
      brandColor: Color(0xFF007E83),
    ),
    'SWIGGY_ONE': ServiceIconEntry(
      glyph: 'S',
      brandColor: Color(0xFFA35A0E),
    ),
    'ZOMATO_GOLD': ServiceIconEntry(
      glyph: 'Z',
      brandColor: Color(0xFF9C2530),
    ),
    'SONYLIV': ServiceIconEntry(
      glyph: 'S',
      brandColor: Color(0xFF14284B),
    ),
    'ZEE5': ServiceIconEntry(
      glyph: 'Z',
      brandColor: Color(0xFF6B2D8B),
    ),
  };

  /// Returns a [ServiceIconEntry] for the given [serviceKey], or `null`
  /// if the service is not in the registry.
  static ServiceIconEntry? lookup(String serviceKey) {
    return _entries[serviceKey];
  }
}
