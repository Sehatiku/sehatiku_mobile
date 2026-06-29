import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/notification_model.dart';
import 'package:sehatiku_mobile/data/services/notification_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await NotificationService.instance.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat notifikasi. Periksa koneksi internet Anda.';
        });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await NotificationService.instance.markAsRead(id);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            if (n.id == id) {
              return NotificationModel(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                createdAt: n.createdAt,
                nakesName: n.nakesName,
                nakesNote: n.nakesNote,
                consultationId: n.consultationId,
                isRead: true,
              );
            }
            return n;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to mark notification $id as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.instance.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              createdAt: n.createdAt,
              nakesName: n.nakesName,
              nakesNote: n.nakesNote,
              consultationId: n.consultationId,
              isRead: true,
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.isNegative) return '0m';

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j';
    } else {
      return '${diff.inDays}h';
    }
  }

  IconData _getIcon(String type, String title) {
    final t = type.toLowerCase();
    final titleLower = title.toLowerCase();
    if (t == 'medicine' || t == 'obat' || titleLower.contains('obat')) {
      return Icons.alarm_rounded;
    }
    if (t == 'ai' || titleLower.contains('ai')) {
      return Icons.auto_awesome_rounded;
    }
    if (t == 'appointment' ||
        t == 'doctor' ||
        t == 'consultation_reply' ||
        titleLower.contains('dokter') ||
        titleLower.contains('janji') ||
        titleLower.contains('balasan') ||
        titleLower.contains('konsultasi')) {
      return Icons.forum_rounded;
    }
    if (t == 'daily_log' || titleLower.contains('harian') || titleLower.contains('catatan')) {
      return Icons.task_alt_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getColor(String type, String title) {
    final t = type.toLowerCase();
    final titleLower = title.toLowerCase();
    if (t == 'medicine' || t == 'obat' || titleLower.contains('obat')) {
      return AppColors.orange;
    }
    if (t == 'ai' || titleLower.contains('ai')) {
      return AppColors.violet;
    }
    if (t == 'appointment' ||
        t == 'doctor' ||
        t == 'consultation_reply' ||
        titleLower.contains('dokter') ||
        titleLower.contains('janji') ||
        titleLower.contains('balasan') ||
        titleLower.contains('konsultasi')) {
      return AppColors.primary;
    }
    if (t == 'daily_log' || titleLower.contains('harian') || titleLower.contains('catatan')) {
      return AppColors.lime;
    }
    return AppColors.primary;
  }

  Color _getBgColor(String type, String title) {
    final t = type.toLowerCase();
    final titleLower = title.toLowerCase();
    if (t == 'medicine' || t == 'obat' || titleLower.contains('obat')) {
      return const Color(0xFFFFF3E0);
    }
    if (t == 'ai' || titleLower.contains('ai')) {
      return const Color(0xFFF0EBFF);
    }
    if (t == 'appointment' ||
        t == 'doctor' ||
        t == 'consultation_reply' ||
        titleLower.contains('dokter') ||
        titleLower.contains('janji') ||
        titleLower.contains('balasan') ||
        titleLower.contains('konsultasi')) {
      return const Color(0xFFEAF2FE);
    }
    if (t == 'daily_log' || titleLower.contains('harian') || titleLower.contains('catatan')) {
      return const Color(0xFFE7F7EC);
    }
    return const Color(0xFFEAF2FE);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_notifications.isEmpty) {
      content = AppCard(
        padding: 24,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: colors.muted.withValues(alpha: 0.4),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum Ada Notifikasi',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pemberitahuan mengenai aktivitas kesehatan Anda akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final hasUnread = _notifications.any((n) => !n.isRead);
      content = Column(
        children: [
          if (hasUnread)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Tandai Semua Dibaca'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ),
          ..._notifications.map((n) {
            return NotifCard(
              icon: _getIcon(n.type, n.title),
              color: _getColor(n.type, n.title),
              bg: _getBgColor(n.type, n.title),
              title: n.title,
              desc: n.message,
              time: _formatRelativeTime(n.createdAt),
              isRead: n.isRead,
              onTap: () => _markAsRead(n.id),
            );
          }),
        ],
      );
    }

    return DetailScaffold(
      title: 'Notifikasi',
      onBack: widget.onBack,
      child: content,
    );
  }
}
