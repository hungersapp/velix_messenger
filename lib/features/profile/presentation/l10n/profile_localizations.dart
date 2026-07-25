import 'package:flutter/widgets.dart';

/// Localization-ready profile copy. Expand per-locale as languages are added.
class ProfileLocalizations {
  const ProfileLocalizations._(this.locale);

  final Locale locale;

  static ProfileLocalizations of(BuildContext context) {
    return ProfileLocalizations._(Localizations.localeOf(context));
  }

  String get slogan {
    switch (locale.languageCode) {
      case 'hi':
        return 'तेज़. सुरक्षित. सरल.';
      case 'ta':
        return 'வேகமாக. பாதுகாப்பாக. எளிதாக.';
      default:
        return 'Fast. Secure. Simple.';
    }
  }

  String get velixIdCopied => switch (locale.languageCode) {
        'hi' => 'Velix ID कॉपी हो गया',
        'ta' => 'Velix ID நகலெடுக்கப்பட்டது',
        _ => 'Velix ID copied',
      };
}
