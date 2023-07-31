import 'message.dart';
import '../helpers/db_setup.dart';
import 'package:sembast/sembast.dart';

enum ChannelType {
  general,
  announcement,
}

class Channel {
  final ChannelType channelType;
  final String name;
  List<Message> messages;

  Channel({
    required this.channelType,
    required this.name,
    List<Message>? messages,
  }) : messages = messages ?? [];
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'channelType': channelType.toString(),
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }

  static Channel fromMap(Map<String, dynamic> map) {
    return Channel(
      name: map['name'],
      channelType: _parseChannelType(map['channelType']),
      messages: (map['messages'] as List<dynamic>)
          .map((message) => Message.fromMap(message))
          .toList(),
    );
  }

  static ChannelType _parseChannelType(String channelType) {
    switch (channelType) {
      case 'ChannelType.general':
        return ChannelType.general;
      case 'ChannelType.announcement':
        return ChannelType.announcement;
      // Add more cases for other channel types if needed
      default:
        throw Exception("Invalid channel type.");
    }
  }

  Future<Database> getDatabase1() async {
    return await setupDatabase1();
  }

  StoreRef<int, Map<String, dynamic>> getStoreRef1() {
    return intMapStoreFactory.store('channels');
  }

  Future<void> createMessage(Message message, String channelName) async {
    var database = await getDatabase1();
    var channelStore = getStoreRef1();
    print(intMapStoreFactory.store('channels'));
   var channelRecords = await channelStore.find(database, finder: Finder());

  print('Printing channelRecords:');
  for (var record in channelRecords) {
    print(record.value);
  }

    // if (channelRecord == null) {
    //   throw Exception("Channel does not exist in the database");
    // }

    // var updatedChannel = Channel.fromMap(channelRecord.value);
    // Add your message creation logic here...
    // For example, you can add the message to the channel's messages list:
    messages.add(message);
    // await channelStore.update(
    //   database,
    //   updatedChannel.toMap(),
    //   finder: Finder(filter: Filter.byKey(channelRecord.key)),
    // );

    print("Message created successfully");
  }
}
