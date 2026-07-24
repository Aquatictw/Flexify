import '../database/database.dart';
import 'duration_format.dart';
import '../utils.dart' as app_utils;

const cardioMetricDuration = 'duration';
const cardioMetricDistance = 'distance';
const cardioMetricSpeed = 'speed';
const cardioMetricIncline = 'incline';

const cardioMetricLabels = {
  cardioMetricDuration: 'Time',
  cardioMetricDistance: 'Distance',
  cardioMetricSpeed: 'Speed',
  cardioMetricIncline: 'Incline',
};

double cardioSpeed(double distance, double durationMinutes) {
  if (durationMinutes <= 0) return 0;
  return distance / durationMinutes * 60;
}

String formatCardioSpeed(double distance, double durationMinutes, String unit) {
  final speed = cardioSpeed(distance, durationMinutes);
  return '${app_utils.toString(speed)} $unit/h';
}

/// Pace as mm:ss per distance unit (e.g. `7:53 min/km`). Empty when undefined.
String formatCardioPace(double distance, double durationMinutes, String unit) {
  if (distance <= 0 || durationMinutes <= 0) return '';
  final paceMinutes = durationMinutes / distance;
  var minutes = paceMinutes.floor();
  var seconds = ((paceMinutes - minutes) * 60).round();
  if (seconds == 60) {
    minutes += 1;
    seconds = 0;
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')} min/$unit';
}

/// Pace derived straight from a speed value (unit/h), e.g. `7:53 min/km`.
String formatPaceFromSpeed(double speed, String unit) =>
    formatCardioPace(speed, 60, unit);

String formatCardioSummary(
  GymSet set,
  String unit, {
  bool includeSpeed = false,
}) {
  final parts = <String>[
    formatDurationMinutes(set.duration),
    '${app_utils.toString(set.distance)} $unit',
  ];
  if (includeSpeed && set.duration > 0 && set.distance > 0) {
    parts.add(formatCardioSpeed(set.distance, set.duration, unit));
    parts.add(formatCardioPace(set.distance, set.duration, unit));
  }
  if (set.incline != null && set.incline! > 0) {
    parts.add('${set.incline}%');
  }
  return parts.join(' · ');
}
