import '../records/records_service.dart';

class SetData {
  SetData({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.savedSetId,
    this.isWarmup = false,
    this.isDropSet = false,
    this.duration = 0,
    this.distance = 0,
    this.incline,
    this.cardioMetric,
    Set<RecordType>? records,
  }) : records = records ?? {};
  double weight;
  int reps;
  double duration;
  double distance;
  int? incline;
  String? cardioMetric;
  bool completed;
  int? savedSetId;
  bool isWarmup;
  bool isDropSet;
  Set<RecordType> records;
}
