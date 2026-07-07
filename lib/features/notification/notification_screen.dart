import 'package:flutter/material.dart';

import 'package:sehatiku_mobile/core/core.dart';
import 'package:sehatiku_mobile/data/models/notification_model.dart';
import 'package:sehatiku_mobile/data/services/notification_service.dart';
import 'package:sehatiku_mobile/shared/widgets/widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.onBack,
    this.onNavigate,
  });

  final VoidCallback onBack;
  final ValueChanged<MainView>? onNavigate;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _selectedTab = 0;

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

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> groups = {
      'Hari Ini': [],
      'Kemarin': [],
      'Lebih Lama': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in list) {
      final createdDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (createdDate.isAtSameMomentAs(today)) {
        groups['Hari Ini']!.add(n);
      } else if (createdDate.isAtSameMomentAs(yesterday)) {
        groups['Kemarin']!.add(n);
      } else {
        groups['Lebih Lama']!.add(n);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  Widget _buildTab(int index, String label) {
    final colors = AppColors.of(context);
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primary2],
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
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
      final filteredList = _selectedTab == 0
          ? _notifications
          : _notifications.where((n) => !n.isRead).toList();

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Row ───────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.line.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTab(0, 'Semua'),
                      const SizedBox(width: 4),
                      _buildTab(1, 'Belum Dibaca'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (hasUnread)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _markAllAsRead,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              color: AppColors.primary,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Baca semua',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Notifications Content ─────────────────────────────────────────
          if (filteredList.isEmpty)
            AppCard(
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
                      _selectedTab == 0 ? 'Belum Ada Notifikasi' : 'Tidak Ada Notifikasi Baru',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTab == 0
                          ? 'Pemberitahuan mengenai aktivitas kesehatan Anda akan muncul di sini.'
                          : 'Semua notifikasi Anda sudah dibaca.',
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
            )
          else
            ...() {
              final groups = _groupNotifications(filteredList);
              return groups.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ...entry.value.map((n) {
                      return NotifCard(
                        icon: _getIcon(n.type, n.title),
                        color: _getColor(n.type, n.title),
                        bg: _getBgColor(n.type, n.title),
                        title: n.title,
                        desc: n.message,
                        time: _formatRelativeTime(n.createdAt),
                        isRead: n.isRead,
                        onTap: () async {
                          await _markAsRead(n.id);
                          if (n.type == 'consultation_reply' && widget.onNavigate != null) {
                            widget.onNavigate!(MainView.dokter);
                          }
                        },
                      );
                    }),
                  ],
                );
              });
            }(),
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
