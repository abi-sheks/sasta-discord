import 'package:dart_application_1/models/ServerNotFoundException.dart';
import 'UserNotFoundException.dart';
import 'channel.dart';
import 'package:dart_application_1/models/user.dart';
import 'message.dart';
import 'package:sembast/sembast.dart';
import '../helpers/db_setup.dart';
import 'role.dart';


class Server {
  final String name;
  List<Role> roles;
  List<Channel> channels;
  List<User> members;

  Server(this.name, {List<Channel>? channels, List<User>? members, List<Role>? roles})
      : channels = channels ?? [],
        members = members ?? [],
        roles = roles ?? [];
  bool isMember(String username) {
    var memberNames = members.map((e) => e.username).toList();
    return memberNames.contains(username);
  }

  void addRole(Role role) {
    roles.add(role);
  }
  void addUserToRole(Role role, User user) {
    role.usersWithRole.add(user);
  }

  void createChannel(Channel channel) {
    channels.add(channel);
  }

// Future<void> createMessage(
//     String sender, String channelName, String message) async {
//   var server = this;
//   var database = await server.getDatabase1();
//   var store = server.getStoreRef();

//   var serverRecord = await store.findFirst(
//     database,
//     finder: Finder(filter: Filter.equals('name', server.name)),
//   );

//   if (serverRecord == null) {
//     throw ServerNotFoundException();
//   } else {
//     var updatedServer = Server.fromMap(serverRecord.value);

//     var requiredSender = updatedServer.members.firstWhere(
//       (member) => member.username == sender,
//       orElse: () =>
//           throw UserNotFoundException("User has not joined this server"),
//     );

//     var requiredChannel = updatedServer.channels.firstWhere(
//       (channel) => channel.name == channelName,
//       orElse: () => throw Exception("Channel does not exist on this server"),
//     );

//     requiredChannel.createMessage(Message(requiredSender, message), roles);

//     await store.update(
//       database,
//       updatedServer.toMap(),
//       finder: Finder(filter: Filter.byKey(serverRecord.key)),
//     );

//     print("Message created successfully");
//   }
// }

  void showMessages() {
    for (Channel channel in channels) {
      print("${channel.name} :");
      for (Message message in channel.messages) {
        print("${message.sender.username} : ${message.contents}");
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'channels': channels.map((channel) => channel.toMap()).toList(),
      'members': members.map((member) => member.toMap()).toList(),
    };
  }

  static Server fromMap(Map<String, dynamic> map) {
    return Server(
      map['name'],
      channels: (map['channels'] as List<dynamic>)
          .map((channel) => Channel.fromMap(channel))
          .toList(),
      members: (map['members'] as List<dynamic>)
          .map((member) => User.fromMap(member))
          .toList(),
    );
  }

  Future<Database> getDatabase1() async {
    return await setupDatabase1();
  }

  StoreRef<int, Map<String, dynamic>> getStoreRef() {
    return intMapStoreFactory.store('servers');
  }
  Role getRole(String roleName){ 
    return roles.firstWhere((role) => role.name == roleName, orElse: () => throw Exception("Role was not found"));
  }
  User getMember(String userName) {
    return members.firstWhere((member) => member.username == userName, orElse: () => throw UserNotFoundException("User was not found on the server"));
  }
}

Future<void> addMember(Server server, User member) async {
  var database = await server.getDatabase1();
  var store = server.getStoreRef();

  var serverRecord = await store.findFirst(
    database,
    finder: Finder(filter: Filter.equals('name', server.name)),
  );

  if (serverRecord == null) {
    throw ServerNotFoundException();
  } else {
    var updatedServer = Server.fromMap(serverRecord.value);
    updatedServer.members.add(member);

    await store.update(
      database,
      updatedServer.toMap(),
      finder: Finder(filter: Filter.byKey(serverRecord.key)),
    );

    print("Member added successfully");
  }
}

bool isMember(Server server, String username) {
  var memberNames = server.members.map((e) => e.username).toList();
  return memberNames.contains(username);
}

