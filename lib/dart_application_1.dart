import "package:dart_application_1/models/User.dart";
import "package:dart_application_1/models/role.dart";
import 'package:dart_application_1/models/server.dart';
import "package:dart_application_1/models/Message.dart";
import "package:dart_application_1/models/Channel.dart";
import 'package:sembast/sembast.dart';
import 'package:dart_application_1/helpers/db_setup.dart';
import "package:dart_application_1/models/ServerNotFoundException.dart";
import "package:dart_application_1/models/UserNotFoundException.dart";
import "package:dart_application_1/models/UserExistsException.dart";
import "package:dart_application_1/enums/permissions.dart";

class DiscordAPI {
  var allUsers = <User>[];
  var allServers = <Server>[];
  Future<void> registerUser(String username) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('users');

    var userNames = await store
        .find(database,
            finder: Finder(filter: Filter.equals('username', username)))
        .then((records) =>
            records.map((record) => User.fromMap(record.value)).toList());

    if (userNames.isNotEmpty) {
      throw UserExistsException();
    } else {
      var user = User(username: username); // Specify the named argument
      await store.add(database, user.toMap());
      print("Success");
    }
  }

  Future<void> sendDirectMessage(
      String sender, String recipient, String message) async {
    var database = await setupDatabase1();
    var store = StoreRef<String, dynamic>.main();

    var userMessages = await store.record(recipient).get(database);

    userMessages ??= {'messages': <dynamic>[]};

    var messages =
        List<dynamic>.from(userMessages['messages'] as List<dynamic>);

    messages.add(message);
    messages.add({'sender': sender, 'contents': message});
    var updatedUserMessages = {...userMessages, 'messages': messages};

    await store.record(recipient).put(database, updatedUserMessages);
    print('Message sent from $sender to $recipient: $message');
  }

  Future<List<String>> getMessages(String username) async {
    var database = await setupDatabase1();
    var store = StoreRef<String, dynamic>.main();

    var userMessages = await store.record(username).get(database);

    if (userMessages != null) {
      var messages = userMessages['messages'] as List<dynamic>?;

      if (messages != null) {
        var formattedMessages = messages.map((msg) {
          if (msg is Map<String, dynamic>) {
            return '${msg['sender']}:${msg['contents']}';
          } else {
            // Handle the case when msg is a string
            return msg.toString();
          }
        }).toList();

        return formattedMessages;
      }
    }

    return []; // Return an empty list if no messages or invalid data
  }

  Future<void> printUserMessages(String sender, String recipient) async {
    var messages = await getMessages(recipient);
    print('Messages between $sender and $recipient:');

    var formattedMessages =
        messages.where((message) => message.contains(':')).map((message) {
      var parts = message.split(':');
      var messageSender = parts[0];
      var messageContent = parts[1];
      return {'sender': messageSender, 'content': messageContent};
    }).toList();

    for (var message in formattedMessages) {
      var messageSender = message['sender'];
      var messageContent = message['content'];
      if (messageSender == sender || messageSender == recipient) {
        print('$messageSender: $messageContent');
      }
    }
  }

  Future<void> loginUser(String username) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('users');

    var userRecord = await store.findFirst(database,
        finder: Finder(filter: Filter.equals('username', username)));

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var user = User.fromMap(userRecord.value);

      if (user.loggedIn == false) {
        user.loggedIn = true;
        await store.update(database, user.toMap(),
            finder: Finder(filter: Filter.byKey(userRecord.key)));
        print("Logged in successfully");
      } else {
        print("User already logged in");
      }
    }
  }

  Future<void> logoutUser(String username) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('users');

    var userRecord = await store.findFirst(database,
        finder: Finder(filter: Filter.equals('username', username)));
    print(userRecord);

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var user = User.fromMap(userRecord.value);

      if (user.loggedIn == true) {
        user.loggedIn = false;
        await store.update(database, user.toMap(),
            finder: Finder(filter: Filter.byKey(userRecord.key)));
        print("Logged out successfully");
      } else {
        print("User is not logged in");
      }
    }
  }

  Future<void> createServer(String serverName) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('servers');

    var server = Server(serverName);

    await store.add(database, server.toMap());

    print("Server created successfully");
  }

  Future<void> addChannelToServer(
      String channelName, String category, String serverName) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('servers');

    var serverRecord = await store.findFirst(
      database,
      finder: Finder(filter: Filter.equals('name', serverName)),
    );

    if (serverRecord == null) {
      throw ServerNotFoundException();
    } else {
      var server = Server.fromMap(serverRecord.value);
      server.createChannel(Channel(category, channelName));

      await store.update(
        database,
        server.toMap(),
        finder: Finder(filter: Filter.byKey(serverRecord.key)),
      );

      print("Channel added to the server successfully");
    }
  }

  Future<void> sendMessage(String senderName, String serverName,
      String channelName, String message) async {
    var server = this.getServer(serverName);
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
        (member) => member.username == senderName,
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

      print("Message sent successfully");
    }
  }

  Future<void> joinServer(String username, String serverName) async {
    var database = await setupDatabase1();
    var userStore = intMapStoreFactory.store('users');
    var serverStore = intMapStoreFactory.store('servers');

    var userRecord = await userStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', username)),
    );

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var user = User.fromMap(userRecord.value);

      if (!user.loggedIn) {
        print("User not logged in");
      } else {
        var requiredUser = User.fromMap(userRecord.value);

        var serverRecord = await serverStore.findFirst(
          database,
          finder: Finder(filter: Filter.equals('name', serverName)),
        );

        if (serverRecord == null) {
          throw ServerNotFoundException();
        } else {
          var requiredServer = Server.fromMap(serverRecord.value);

          if (requiredServer.isMember(username)) {
            throw Exception("The user is already a member of the server");
          } else {
            requiredServer.members.add(requiredUser);

            await serverStore.update(
              database,
              requiredServer.toMap(),
              finder: Finder(filter: Filter.byKey(serverRecord.key)),
            );

            print("User joined the server successfully");
          }
        }
      }
    }
  }

  void printMessages(String serverName) {
    var requiredServer = allServers.firstWhere(
      (server) => server.name == serverName,
      orElse: () => throw ServerNotFoundException(),
    );

    for (Channel channel in requiredServer.channels) {
      print("${channel.name} :");
      for (Message message in channel.messages) {
        print("${message.sender.username} : ${message.contents}");
      }
    }
  }

  void createRole(String serverName, String? roleName, String? rolePerm) {
    var server = this.getServer(serverName);
    if (roleName == null) {
      throw Exception("Please provide a name for the role");
    }
    if (rolePerm == null) {
      server.addRole(Role(roleName, Perm.member));
      return;
    }
    if (rolePerm == "moderator") {
      server.addRole(Role(roleName, Perm.moderator));
      return;
    }
    server.addRole(Role(roleName, Perm.member));
  }

  void assignRole(String serverName, String roleName, String username) {
    var server = this.getServer(serverName);
    var reqRole = server.getRole(roleName);
    var reqUser = server.getMember(username);
    reqRole.usersWithRole.add(reqUser);
  }

  Server getServer(String name) {
    return allServers.firstWhere((server) => server.name == name,
        orElse: () => throw ServerNotFoundException());
  }
}
