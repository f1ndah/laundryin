import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../theme.dart';
import 'app_dialog.dart';

class AppAbout {
  static IconButton action(BuildContext context) => IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: 'Tentang Aplikasi',
        onPressed: () => show(context),
      );

  static Future<void> show(BuildContext context) {
    return AppDialog.show(
      context: context,
      builder: (ctx) => FutureBuilder<VersionStatus>(
        future: AppVersionService.check(),
        builder: (context, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          final status = snap.data;

          return AppDialog.themed(
            context: ctx,
            title: 'Tentang LaundryIN',
            content: [
              const Icon(Icons.local_laundry_service, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('LaundryIN', style: AppTextStyles.heading, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Cuci baju tanpa ribet',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                Text(
                  'Versi ${status?.local ?? '-'}',
                  style: AppTextStyles.bodyBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(child: _badge(status)),
                if (status?.checked == true && status?.remote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'GitHub: v${status!.remote}',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ],
          );
        },
      ),
    );
  }

  static Widget _badge(VersionStatus? status) {
    if (status == null || !status.checked) {
      return Chip(
        avatar: const Icon(Icons.cloud_off, size: 16, color: Colors.grey),
        label: const Text('Status tidak diketahui'),
        backgroundColor: Colors.grey.shade200,
        labelStyle: const TextStyle(fontSize: 12),
        visualDensity: VisualDensity.compact,
      );
    }
    if (status.isLatest) {
      return Chip(
        avatar: Icon(Icons.verified, size: 16, color: Colors.green.shade700),
        label: const Text('Latest'),
        backgroundColor: Colors.green.shade50,
        labelStyle: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold),
        visualDensity: VisualDensity.compact,
      );
    }
    return Chip(
      avatar: Icon(Icons.system_update, size: 16, color: Colors.orange.shade800),
      label: Text('Update tersedia (v${status.remote})'),
      backgroundColor: Colors.orange.shade50,
      labelStyle: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
      visualDensity: VisualDensity.compact,
    );
  }
}
