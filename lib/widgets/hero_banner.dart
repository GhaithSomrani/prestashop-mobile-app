import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

/// Hero banner with large image and CTA button
class HeroBanner extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const HeroBanner({
    super.key,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    this.buttonText = 'Shop Now',
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Stack(
        children: [
          // Background Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
                placeholder: (context, url) => Container(
                  color: AppTheme.primaryBlack,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.primaryBlack,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pureWhite,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.pureWhite.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureWhite,
                    foregroundColor: AppTheme.primaryBlack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing3,
                      vertical: AppTheme.spacing1,
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
