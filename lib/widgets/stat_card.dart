import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final valueFontSize = isMobile ? 20.0 : 28.0;
    final titleFontSize = isMobile ? 11.0 : 13.0;
    final avatarRadius = isMobile ? 16.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 10.0 : AppColors.spacing16),
      decoration: EmeraldTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radius16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.ivoryLight,
              radius: avatarRadius,
              child: Icon(icon, color: AppColors.goldWarm, size: isMobile ? 16 : AppColors.iconSmall),
            ),
            const SizedBox(width: AppColors.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: AppColors.emeraldTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
