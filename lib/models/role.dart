import '../enums/permissions.dart';
import 'user.dart';

class Role {
  final String name;
  final Perm accessLevel;
  var usersWithRole = <User>[];
  Role(this.name, this.accessLevel);
}