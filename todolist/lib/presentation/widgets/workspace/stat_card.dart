import 'package:flutter/material.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';

/// Responsive stat card widget with WCAG compliance
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      child: RepaintBoundary(
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppConstants.minTouchTarget,
              ),
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 150;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: color,
                        size: isCompact ? AppConstants.iconL : AppConstants.iconXl,
                        semanticLabel: label,
                      ),
                      SizedBox(height: isCompact ? AppConstants.spacingXs : AppConstants.spacingS),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppConstants.spacingXs),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
