import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../services/data_retention_service.dart';

/// Privacy notice dialog — UK GDPR Arts. 12-14 transparency requirement.
/// Accessible from the login screen and settings.
class PrivacyNoticeDialog {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const _PrivacyNoticeDialog(),
    );
  }
}

class _PrivacyNoticeDialog extends StatelessWidget {
  const _PrivacyNoticeDialog();

  @override
  Widget build(BuildContext context) {
    final retention = DataRetentionService.getRetentionPolicy();

    return Dialog(
      backgroundColor: AppColors.dashboardCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.privacy_tip, color: AppColors.champagneGold, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy Notice',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warmWhite,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.warmGray),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.dashboardBorder, height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Data Controller',
                          'Paradise Assembly of God Church (the "Church") is the data controller '
                          'for the personal data processed through this application. The Church '
                          'is responsible for complying with the UK GDPR and Data Protection Act 2018.'),
                      _section('Data We Collect',
                          '• Member information: name, email, phone, address\n'
                          '• User accounts: name, email, phone, role\n'
                          '• Financial records: tithes, offerings, donations, transactions\n'
                          '• Attendance records: service and event attendance\n'
                          '• Welfare cases: case details and financial assistance\n'
                          '• Audit logs: user actions and system events'),
                      _section('Lawful Basis',
                          'We process personal data under the lawful basis of legitimate '
                          'interests (UK GDPR Art. 6(1)(f)) for church administration, '
                          'and legal obligation for financial record-keeping (HMRC requirements).'),
                      _section('Data Storage',
                          'Your data is stored locally on this device using encrypted storage. '
                          'If cloud sync is enabled, data is also stored in a secure cloud database '
                          'with Row-Level Security policies. Password hashes are never synced to the cloud.'),
                      _section('Data Retention',
                          retention.entries.map((e) => '• ${e.key}: ${e.value}').join('\n')),
                      _section('Your Rights',
                          'Under UK GDPR you have the right to:\n'
                          '• Access your personal data (Art. 15)\n'
                          '• Rectify inaccurate data (Art. 16)\n'
                          '• Erase your data (Art. 17)\n'
                          '• Restrict processing (Art. 18)\n'
                          '• Data portability (Art. 20)\n'
                          '• Object to processing (Art. 21)\n\n'
                          'To exercise these rights, contact your church administrator.'),
                      _section('Security Measures',
                          '• Passwords are hashed using PBKDF2 with per-user salt (100,000 iterations)\n'
                          '• Local data is encrypted at rest using AES-256\n'
                          '• Backups are encrypted using AES-256-GCM\n'
                          '• Session timeout after 15 minutes of inactivity\n'
                          '• Login rate limiting (5 attempts → 15-min lockout)\n'
                          '• Audit logging of all data access and modifications'),
                      _section('Contact',
                          'For privacy enquiries or to exercise your data protection rights, '
                          'contact the church administrator or the Data Protection Officer.'),
                      const SizedBox(height: 16),
                      Text(
                        'This notice is provided in accordance with UK GDPR Arts. 12-14 '
                        'and the Data Protection Act 2018.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.warmGray,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagneGold,
                    foregroundColor: AppColors.dashboardBackground,
                  ),
                  child: Text('I Understand',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.champagneGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.warmWhite,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
