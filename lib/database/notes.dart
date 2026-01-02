import 'package:drift/drift.dart';

@DataClassName('Note')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();
  IntColumn get color => integer().nullable()();
}
