import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> setupDatabase1() async {
  var dbPath1 = r'lib\models\Users.db';
  var database1 = await databaseFactoryIo.openDatabase(dbPath1);
  return database1;
}