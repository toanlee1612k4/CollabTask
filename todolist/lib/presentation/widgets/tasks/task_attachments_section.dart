import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todolist/core/constants/app_design_system.dart';
import 'package:todolist/data/services/api_client.dart';
import 'package:todolist/data/models/models.dart' show TaskAttachment;

/// File Attachments Widget for Task Detail
/// Supports: Upload, Download, Delete files
class TaskAttachmentsSection extends StatefulWidget {
  final String taskId;
  final String currentUserId;
  final bool canDelete; // Owner or PM
  final bool isAssignee; // Can upload files

  const TaskAttachmentsSection({
    super.key,
    required this.taskId,
    required this.currentUserId,
    required this.canDelete,
    required this.isAssignee,
  });

  @override
  State<TaskAttachmentsSection> createState() => _TaskAttachmentsSectionState();
}

class _TaskAttachmentsSectionState extends State<TaskAttachmentsSection> {
  final ApiClient _apiClient = ApiClient();
  
  List<TaskAttachment> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attachments = await _apiClient.getTaskAttachments(widget.taskId);

      if (mounted) {
        setState(() {
          _attachments = attachments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'png', 'jpg', 'jpeg', 'gif', 'txt', 'zip'],
      );

      if (result == null) return; // User cancelled

      final file = result.files.first;

      // Check file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File quá lớn! Giới hạn 10MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload using API client method
      await _apiClient.uploadAttachment(
        widget.taskId,
        file,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      // Reload list
      await _loadAttachments();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã upload ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        // Handle 403 Forbidden - not assignee
        String errorMessage = 'Lỗi upload: $e';
        if (e.toString().contains('403')) {
          errorMessage = 'Chỉ thành viên được gán mới có thể upload file';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(TaskAttachment attachment) async {
    try {
      if (kIsWeb) {
        // Web: Open in new tab
        final url = '${_apiClient.baseUrl}${attachment.downloadUrl}';
        // TODO: Use url_launcher to open in new tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading: $url')),
        );
      } else {
        // Mobile/Desktop: Download to device
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${attachment.fileName}';

        await _apiClient.dio.download(
          attachment.downloadUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
            }
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tải ${attachment.fileName}')),
          );

          // Open file
          await OpenFile.open(filePath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(TaskAttachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa file "${attachment.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.deleteAttachment(
        widget.taskId,
        attachment.attachmentID,
      );

      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with upload button
        Row(
          children: [
            Icon(Icons.attach_file, size: 20, color: AppColors.textHint),
            const SizedBox(width: 8),
            Text(
              'File đính kèm (${_attachments.length})',
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodyMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!_isUploading)
              IconButton(
                onPressed: widget.isAssignee ? _uploadFile : null,
                icon: const Icon(Icons.upload_file),
                tooltip: widget.isAssignee ? 'Upload file' : 'Chỉ assignee có thể upload',
                color: widget.isAssignee ? AppColors.primary : AppColors.textHint,
              ),
          ],
        ),
        
        // Show message if not assignee
        if (!widget.isAssignee)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'Chỉ thành viên được gán mới có thể upload file',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        const SizedBox(height: AppSpacing.sm),

        // Upload progress
        if (_isUploading) ...[
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đang upload... ${(_uploadProgress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: AppTypography.bodySmall,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Loading state
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          ),

        // Error state
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lỗi: $_error',
                    style: GoogleFonts.inter(
                      fontSize: AppTypography.bodySmall,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Empty state
        if (!_isLoading && _attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.file_present_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có file đính kèm',
                    style: GoogleFonts.inter(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Attachments list
        if (!_isLoading && _attachments.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              return _buildAttachmentCard(_attachments[index]);
            },
          ),
      ],
    );
  }

  Widget _buildAttachmentCard(TaskAttachment attachment) {
    final canDelete = widget.canDelete || attachment.uploadedByUserID == widget.currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getFileColor(attachment.fileType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            _getFileIcon(attachment.fileType),
            color: _getFileColor(attachment.fileType),
          ),
        ),
        title: Text(
          attachment.fileName,
          style: GoogleFonts.inter(
            fontSize: AppTypography.bodyMedium,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatFileSize(attachment.fileSize)} • ${attachment.uploadedByName}',
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textHint,
              ),
            ),
            Text(
              _formatDate(attachment.uploadedAt),
              style: GoogleFonts.inter(
                fontSize: AppTypography.bodySmall,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(attachment),
              tooltip: 'Download',
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFile(attachment),
                tooltip: 'Xóa',
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('word') || fileType.contains('document')) return Icons.description;
    if (fileType.contains('excel') || fileType.contains('spreadsheet')) return Icons.table_chart;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('zip')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileType) {
    if (fileType.contains('pdf')) return Colors.red;
    if (fileType.contains('word')) return Colors.blue;
    if (fileType.contains('excel')) return Colors.green;
    if (fileType.contains('image')) return Colors.purple;
    if (fileType.contains('zip')) return Colors.orange;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

