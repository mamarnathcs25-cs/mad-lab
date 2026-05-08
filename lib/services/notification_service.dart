import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void> Function(String medicineId)? _markTakenHandler;
  String? _pendingMedicineId;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(_defaultLocation());

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      _pendingMedicineId = launchPayload;
    }
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (!medicine.remindersEnabled) {
      return;
    }

    await cancelMedicineReminder(medicine.id);

    await _scheduleAt(
      id: _primaryNotificationIdFor(medicine.id),
      title: '${medicine.name} reminder',
      body:
          '${_formatTime(medicine.reminderHour, medicine.reminderMinute)} ${_mealLabel(medicine.mealTiming)} - ${medicine.dosage.isEmpty ? medicine.name : medicine.dosage}',
      hour: medicine.reminderHour,
      minute: medicine.reminderMinute,
      payload: medicine.id,
    );

    final followUps = _followUpTimesFor(medicine);
    for (var i = 0; i < followUps.length; i++) {
      final followUp = followUps[i];
      await _scheduleAt(
        id: _followUpNotificationIdFor(medicine.id, i + 1),
        title: '${medicine.name} follow-up',
        body:
            'This medicine is still pending today. Tap to mark it as taken.',
        hour: followUp.$1,
        minute: followUp.$2,
        payload: medicine.id,
      );
    }
  }

  Future<void> cancelMedicineReminder(String medicineId) async {
    await _plugin.cancel(id: _primaryNotificationIdFor(medicineId));
    await _plugin.cancel(id: _followUpNotificationIdFor(medicineId, 1));
    await _plugin.cancel(id: _followUpNotificationIdFor(medicineId, 2));
  }

  Future<void> dismissActiveMedicineNotification(String medicineId) async {
    await cancelMedicineReminder(medicineId);
  }

  Future<void> attachMarkTakenHandler(
    Future<void> Function(String medicineId) handler,
  ) async {
    _markTakenHandler = handler;
    final pendingMedicineId = _pendingMedicineId;
    if (pendingMedicineId == null) {
      return;
    }
    _pendingMedicineId = null;
    await handler(pendingMedicineId);
  }

  int _primaryNotificationIdFor(String medicineId) {
    return medicineId.hashCode & 0x7fffffff;
  }

  int _followUpNotificationIdFor(String medicineId, int slot) {
    return ((medicineId.hashCode & 0x7fffffff) + (slot * 1000003)) &
        0x7fffffff;
  }

  String _mealLabel(MealTiming timing) {
    switch (timing) {
      case MealTiming.beforeMeal:
        return 'before meal';
      case MealTiming.afterMeal:
        return 'after meal';
    }
  }

  String _formatTime(int hour, int minute) {
    final normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    final scheduledDate = _nextInstanceOf(hour: hour, minute: minute);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Scheduled medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'mark_taken',
              'Mark as taken',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  List<(int, int)> _followUpTimesFor(Medicine medicine) {
    final times = <(int, int)>[];
    final mainMinutes = (medicine.reminderHour * 60) + medicine.reminderMinute;
    const afternoonMinutes = 14 * 60;
    const nightMinutes = 20 * 60 + 30;

    if (mainMinutes < afternoonMinutes) {
      times.add((14, 0));
    }
    if (mainMinutes < nightMinutes) {
      times.add((20, 30));
    }
    return times;
  }

  tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.Location _defaultLocation() {
    try {
      return tz.getLocation('Asia/Kolkata');
    } catch (_) {
      return tz.UTC;
    }
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final medicineId = response.payload;
    if (medicineId == null || medicineId.isEmpty) {
      return;
    }
    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification ||
        response.actionId == 'mark_taken') {
      await dismissActiveMedicineNotification(medicineId);
      final handler = _markTakenHandler;
      if (handler == null) {
        _pendingMedicineId = medicineId;
        return;
      }
      await handler(medicineId);
    }
  }
}
