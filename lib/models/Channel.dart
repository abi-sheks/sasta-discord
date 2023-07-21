import 'message.dart';
import '../helpers/db_setup.dart';
import 'package:sembast/sembast.dart';
import '../enums/permissions.dart';
import 'role.dart';

class Channel {
  final Perm? channelPerm;
  final String name;
  List<Message> messages;

  Channel(this.channelPerm, this.name, {List<Message>? messages})
      : messages = messages ?? [];

  Map<String, dynamic> toMap() {
    return {
      'channelPerm': channelPerm,
      'name': name,
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }

  static Channel fromMap(Map<String, dynamic> map) {
    return Channel(
      map['channelPerm'],
      map['name'],
      messages: (map['messages'] as List<dynamic>)
          .map((message) => Message.fromMap(message))
          .toList(),
    );
  }

  Future<Database> getDatabase1() async {
    return await setupDatabase1();
  }

  StoreRef<int, Map<String, dynamic>> getStoreRef() {
    return intMapStoreFactory.store('channels');
  }

  Future<void> createMessage(Message message, List<Role> serverRoles) async {
    var database = await getDatabase1();
    var store = getStoreRef();

    var channelRecord = await store.findFirst(
      database,
      finder: Finder(
        filter: Filter.equals('name', name),
      ),
    );

    if (channelRecord == null) {
      throw Exception("Channel does not exist in the database");
    }
      var updatedChannel = Channel.fromMap(channelRecord.value);
      if(channelPerm == Perm.member)
      {
        messages.add(message);
      }
      else {
      var senderRole = serverRoles.firstWhere((role) => role.usersWithRole.contains(message.sender), orElse: () => throw Exception("The sender does not have permission to send messages in this channel"));
      if(senderRole.accessLevel == Perm.moderator) 
      {
        messages.add(message);
      }
      else throw Exception("The sender does not have permission to send messages in this channel");
      }
      await store.update(
        database,
        updatedChannel.toMap(),
        finder: Finder(filter: Filter.byKey(channelRecord.key)),
      );

      print("Message created successfully");
  }
}

