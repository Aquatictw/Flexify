// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';
import 'package:drift/internal/migrations.dart';
import 'schema_v31.dart' as v31;
import 'schema_v48.dart' as v48;
import 'schema_v52.dart' as v52;
import 'schema_v57.dart' as v57;
import 'schema_v61.dart' as v61;
import 'schema_v67.dart' as v67;
import 'schema_v71.dart' as v71;

class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    switch (version) {
      case 31:
        return v31.DatabaseAtV31(db);
      case 48:
        return v48.DatabaseAtV48(db);
      case 52:
        return v52.DatabaseAtV52(db);
      case 57:
        return v57.DatabaseAtV57(db);
      case 61:
        return v61.DatabaseAtV61(db);
      case 67:
        return v67.DatabaseAtV67(db);
      case 71:
        return v71.DatabaseAtV71(db);
      default:
        throw MissingSchemaException(version, versions);
    }
  }

  static const versions = const [31, 48, 52, 57, 61, 67, 71];
}
