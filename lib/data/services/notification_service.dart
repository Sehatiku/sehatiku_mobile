import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sehatiku_mobile/data/models/notification_model.dart';
import 'package:sehatiku_mobile/data/services/api_client.dart';

/// Service for patient actor to load notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// GET /api/v1/patients/notifications
  ///
  /// Throws [ApiException] on failure.
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/notifications');
      debugPrint('DEBUG: fetchNotifications response: ${resp.data}');
      final data = resp.data['data'];
      if (data is List) {
        return data
            .map((json) {
              if (json is Map) {
                return NotificationModel.fromJson(Map<String, dynamic>.from(json));
              }
              return null;
            })
            .whereType<NotificationModel>()
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      debugPrint('DEBUG: fetchNotifications error (Dio): $e');
      throw apiExceptionFrom(e);
    } catch (e, stack) {
      debugPrint('DEBUG: fetchNotifications error (parsing): $e\n$stack');
      rethrow;
    }
  }

  /// GET /api/v1/patients/notifications/unread-count
  ///
  /// Throws [ApiException] on failure.
  Future<int> fetchUnreadCount() async {
    try {
      final resp = await ApiClient.instance.get('/api/v1/patients/notifications/unread-count');
      debugPrint('DEBUG: fetchUnreadCount response: ${resp.data}');
      final data = resp.data['data'];
      if (data is Map) {
        return (data['unread_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      debugPrint('DEBUG: fetchUnreadCount error (Dio): $e');
      throw apiExceptionFrom(e);
    } catch (e, stack) {
      debugPrint('DEBUG: fetchUnreadCount error (parsing): $e\n$stack');
      rethrow;
    }
  }

  /// PATCH /api/v1/patients/notifications/{id}/read
  ///
  /// Throws [ApiException] on failure.
  Future<void> markAsRead(String id) async {
    try {
      final resp = await ApiClient.instance.patch('/api/v1/patients/notifications/$id/read');
      debugPrint('DEBUG: markAsRead response: ${resp.data}');
    } on DioException catch (e) {
      debugPrint('DEBUG: markAsRead error (Dio): $e');
      throw apiExceptionFrom(e);
    } catch (e) {
      debugPrint('DEBUG: markAsRead error: $e');
      rethrow;
    }
  }

  /// POST /api/v1/patients/notifications/read-all
  ///
  /// Throws [ApiException] on failure.
  Future<int> markAllAsRead() async {
    try {
      final resp = await ApiClient.instance.post('/api/v1/patients/notifications/read-all');
      debugPrint('DEBUG: markAllAsRead response: ${resp.data}');
      final data = resp.data['data'];
      if (data is Map) {
        return (data['updated_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      debugPrint('DEBUG: markAllAsRead error (Dio): $e');
      throw apiExceptionFrom(e);
    } catch (e) {
      debugPrint('DEBUG: markAllAsRead error: $e');
      rethrow;
    }
  }
}
