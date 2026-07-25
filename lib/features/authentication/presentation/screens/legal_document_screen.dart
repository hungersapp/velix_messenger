import 'package:flutter/material.dart';

/// Full-screen legal document viewer (Terms / Privacy).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                32,
              ),
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: July 25, 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                for (final section in sections) ...[
                  Text(
                    section.heading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const sections = <LegalSection>[
    LegalSection(
      heading: '1. Agreement to Terms',
      body:
          'By creating a Velix Messenger account or using our services, you agree to these Terms & Conditions. If you do not agree, do not create an account or use the app. These terms form a binding agreement between you and Velix Messenger.',
    ),
    LegalSection(
      heading: '2. Eligibility',
      body:
          'You must be at least 18 years old to create an account and use Velix Messenger. By registering, you confirm that you meet this age requirement and that the information you provide is accurate and complete.',
    ),
    LegalSection(
      heading: '3. Account Registration',
      body:
          'You are responsible for maintaining the confidentiality of your Velix User ID, password, and Recovery Security Key. You must not share your Recovery Security Key with others. You are responsible for all activity that occurs under your account. Notify us promptly if you believe your account has been compromised.',
    ),
    LegalSection(
      heading: '4. Acceptable Use',
      body:
          'You agree not to use Velix Messenger to harass, threaten, defraud, or harm others; distribute illegal, abusive, or infringing content; attempt to access accounts or systems without authorization; reverse engineer, disrupt, or overload our services; or violate applicable laws or regulations. We may suspend or terminate accounts that violate these rules.',
    ),
    LegalSection(
      heading: '5. User Content',
      body:
          'You retain ownership of content you send through Velix Messenger. You grant Velix Messenger a limited license to host, transmit, and display that content solely as needed to operate the service. You are solely responsible for the content you share and for obtaining any rights required to share it.',
    ),
    LegalSection(
      heading: '6. Privacy',
      body:
          'Our collection and use of personal information is described in the Privacy Policy. By using Velix Messenger, you also acknowledge that policy.',
    ),
    LegalSection(
      heading: '7. Service Availability',
      body:
          'We aim to keep Velix Messenger reliable, but we do not guarantee uninterrupted or error-free operation. Features may change, and we may modify, suspend, or discontinue parts of the service with or without notice when reasonably necessary.',
    ),
    LegalSection(
      heading: '8. Disclaimers',
      body:
          'Velix Messenger is provided on an “as is” and “as available” basis to the fullest extent permitted by law. We disclaim warranties of merchantability, fitness for a particular purpose, and non-infringement, except where such disclaimers are not allowed.',
    ),
    LegalSection(
      heading: '9. Limitation of Liability',
      body:
          'To the maximum extent permitted by law, Velix Messenger and its operators shall not be liable for indirect, incidental, special, consequential, or punitive damages, or for loss of profits, data, or goodwill arising from your use of the service.',
    ),
    LegalSection(
      heading: '10. Termination',
      body:
          'You may stop using Velix Messenger at any time. We may suspend or terminate access if you violate these terms, if required by law, or to protect the service or other users.',
    ),
    LegalSection(
      heading: '11. Changes to These Terms',
      body:
          'We may update these Terms & Conditions from time to time. Continued use of Velix Messenger after changes become effective constitutes acceptance of the revised terms. Material changes will be reflected by updating the “Last updated” date on this page.',
    ),
    LegalSection(
      heading: '12. Contact',
      body:
          'For questions about these Terms & Conditions, contact Velix Messenger support through the in-app help options or the support channel published on our official website.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms & Conditions',
      sections: sections,
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = <LegalSection>[
    LegalSection(
      heading: '1. Introduction',
      body:
          'This Privacy Policy explains how Velix Messenger collects, uses, stores, and protects information when you create an account or use our messaging services. We are committed to safeguarding your privacy and giving you clear control over your data.',
    ),
    LegalSection(
      heading: '2. Information We Collect',
      body:
          'Depending on how you use Velix Messenger, we may process: display name and username; Velix User ID; authentication credentials (passwords are handled by our authentication provider and are not stored in plaintext); a hashed Recovery Security Key; profile details you choose to add (such as photo or about text); device and app diagnostics needed for reliability and security; and message metadata required to deliver conversations.',
    ),
    LegalSection(
      heading: '3. Information We Do Not Require',
      body:
          'Velix Messenger account creation does not require an email address or mobile phone number. Password recovery is designed around your Velix User ID and Recovery Security Key.',
    ),
    LegalSection(
      heading: '4. How We Use Information',
      body:
          'We use your information to create and secure your account; authenticate sign-in; deliver messaging and related features; prevent abuse, fraud, and unauthorized access; improve performance and reliability; and comply with legal obligations.',
    ),
    LegalSection(
      heading: '5. Recovery Security Key',
      body:
          'Your Recovery Security Key is shown once at registration. We store only a secure hash of that key. We cannot reconstruct the original key. If you lose both your password and Recovery Security Key, account recovery may not be possible.',
    ),
    LegalSection(
      heading: '6. Sharing of Information',
      body:
          'We do not sell your personal information. We may share limited data with service providers who help us operate authentication, hosting, or analytics, only as needed to provide Velix Messenger, and subject to appropriate safeguards. We may disclose information when required by law or to protect users and the integrity of the service.',
    ),
    LegalSection(
      heading: '7. Data Retention',
      body:
          'We retain account and service data for as long as your account remains active and as needed to provide the service, resolve disputes, enforce agreements, and meet legal requirements. You may request account deletion through supported in-app or support channels.',
    ),
    LegalSection(
      heading: '8. Security',
      body:
          'We use industry-standard technical and organizational measures to protect your information, including encrypted transport and hashed recovery credentials. No method of transmission or storage is completely secure, so we encourage strong passwords and safe handling of your Recovery Security Key.',
    ),
    LegalSection(
      heading: '9. Your Choices',
      body:
          'You may update profile information available in the app, protect your account with a strong password, and store your Recovery Security Key offline in a safe place. Where applicable law provides rights of access, correction, deletion, or restriction, we will honor valid requests.',
    ),
    LegalSection(
      heading: '10. Children’s Privacy',
      body:
          'Velix Messenger is not intended for anyone under 18. We do not knowingly collect personal information from children. If we learn that an underage account was created, we will take steps to delete it.',
    ),
    LegalSection(
      heading: '11. International Processing',
      body:
          'Your information may be processed in countries where we or our service providers operate. Where required, we use appropriate safeguards for cross-border transfers.',
    ),
    LegalSection(
      heading: '12. Changes to This Policy',
      body:
          'We may update this Privacy Policy periodically. The “Last updated” date at the top of this page will change when revisions are published. Continued use of Velix Messenger after an update means you acknowledge the revised policy.',
    ),
    LegalSection(
      heading: '13. Contact',
      body:
          'If you have privacy questions or requests, contact Velix Messenger support through the in-app help options or the support channel published on our official website.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      sections: sections,
    );
  }
}
