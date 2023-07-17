import 'Message.dart';
import 'Server.dart';
import '../helpers/db_setup.dart';
import "ServerNotFoundException.dart";
import 'package:sembast/sembast.dart';

class Channel {
  final String? category;
  final String name;
  List<Message> messages;

  Channel(this.category, this.name, {List<Message>? messages})
      : messages = messages ?? [];

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'name': name,
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }

  static Channel fromMap(Map<String, dynamic> map) {
    return Channel(
      map['category'],
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

  Future<void> createMessage(Message message) async {
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
    } else {
      var updatedChannel = Channel.fromMap(channelRecord.value);
      updatedChannel.messages.add(message);

      await store.update(
        database,
        updatedChannel.toMap(),
        finder: Finder(filter: Filter.byKey(channelRecord.key)),
      );

      print("Message created successfully");
    }
  }
}

Future<void> createChannel(Server server, Channel channel) async {
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
    updatedServer.channels.add(channel);

    await store.update(
      database,
      updatedServer.toMap(),
      finder: Finder(filter: Filter.byKey(serverRecord.key)),
    );

    print("Channel created successfully");
  }
}