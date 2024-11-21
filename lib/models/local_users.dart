import 'package:hive/hive.dart';
import 'package:solace/models/local_user.dart';

part 'local_users.g.dart';

@HiveType(typeId: 0)
class LocalUsers extends HiveObject {
  @HiveField(0)
  List<LocalUser>? localUsers;
}