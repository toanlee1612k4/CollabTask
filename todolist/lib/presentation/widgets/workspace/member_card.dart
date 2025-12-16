import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:todolist/core/theme/app_theme.dart';
import 'package:todolist/core/constants/app_constants.dart';
import 'package:todolist/data/models/models.dart';

/// Member card widget with avatar and task count
class MemberCard extends StatelessWidget {
  final UserModel member;
  final int taskCount;
  final int completedCount;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.taskCount,
    required this.completedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < AppConstants.mobileBreakpoint;
    
    return Semantics(
      label: '${member.fullName ?? member.email}, $taskCount nhiệm vụ, $completedCount hoàn thành',
      button: onTap != null,
      child: RepaintBoundary(
        child: Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(isCompact),
                  SizedBox(width: isCompact ? AppConstants.spacingS : AppConstants.spacingM),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName ?? member.email.split('@')[0],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppConstants.spacingXs),
                        Text(
                          member.email,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppConstants.spacingS),
                        Wrap(
                          spacing: AppConstants.spacingS,
                          children: [
                            _buildBadge(
                              context,
                              '$taskCount tasks',
                              AppTheme.infoColor,
                            ),
                            _buildBadge(
                              context,
                              '$completedCount hoàn thành',
                              AppTheme.successColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow icon
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: AppConstants.iconS,
                      color: AppTheme.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isCompact) {
    final size = isCompact ? 40.0 : 56.0;
    final initial = (member.fullName ?? member.email)[0].toUpperCase();
    
    return Semantics(
      image: true,
      label: 'Ảnh đại diện của ${member.fullName ?? member.email}',
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppTheme.accentColor,
        backgroundImage: member.avatar != null && member.avatar!.isNotEmpty
            ? CachedNetworkImageProvider(member.avatar!)
            : null,
        child: member.avatar == null || member.avatar!.isEmpty
            ? Text(
                initial,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: isCompact ? 18 : 24,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
