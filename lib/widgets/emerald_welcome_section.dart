import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

class EmeraldWelcomeSection extends StatelessWidget {
  final String userName;
  final String role;

  const EmeraldWelcomeSection({
    super.key,
    required this.userName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    } else {
      greeting = 'Good Evening,';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: AppColors.spacing16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.emeraldTextSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    color: AppColors.emeraldTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back! Here\'s what\'s happening today.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.emeraldTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing12, vertical: AppColors.spacing8),
            decoration: BoxDecoration(
              color: AppColors.ivoryLight,
              borderRadius: BorderRadius.circular(AppColors.radius16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEE').format(now),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.emeraldTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(now),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.emeraldTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
