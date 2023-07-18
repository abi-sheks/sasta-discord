import 'package:dart_application_1/models/ServerNotFoundException.dart';
import 'UserNotFoundException.dart';
import 'Channel.dart';
import 'package:dart_application_1/models/User.dart';
import 'Message.dart';
import 'package:sembast/sembast.dart';
import '../helpers/db_setup.dart';


class Server {
  final String name;
  List<Channel> channels;
  List<User> members;

  Server(this.name, {List<Channel>? channels, List<User>? members})
      : channels = channels ?? [],
        members = members ?? [];
  bool isMember(String username) {
    var memberNames = members.map((e) => e.username).toList();
    return memberNames.contains(username);
  }

  void createChannel(Channel channel) {
    channels.add(channel);
    for (Channel channel in channels) {
      print("${channel.name}");
    }
  }

  void createMessage(String sender, String channelName, String message) {
    var requiredSender = members.firstWhere(
      (member) => member.username == sender,
      orElse: () =>
          throw UserNotFoundException("User has not joined this server"),
    );

    var requiredChannel = channels.firstWhere(
      (channel) => channel.name == channelName,
      orElse: () => throw Exception("Channel does not exist on this server"),
    );

    requiredChannel.messages.add(Message(requiredSender, message));
  }

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

Future<void> createMessage(
    String sender, Server server, String channelName, String message) async {
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

    var requiredSender = updatedServer.members.firstWhere(
      (member) => member.username == sender,
      orElse: () =>
          throw UserNotFoundException("User has not joined this server"),
    );

    var requiredChannel = updatedServer.channels.firstWhere(
      (channel) => channel.name == channelName,
      orElse: () => throw Exception("Channel does not exist on this server"),
    );

    requiredChannel.messages.add(Message(requiredSender, message));

    await store.update(
      database,
      updatedServer.toMap(),
      finder: Finder(filter: Filter.byKey(serverRecord.key)),
    );

    print("Message created successfully");
  }
}

void showMessages(Server server) {
  for (Channel channel in server.channels) {
    print("${channel.name} :");
    for (Message message in channel.messages) {
      print("${message.sender.username} : ${message.contents}");
    }
  }
}