import 'package:args/args.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'dart:async';

Future<Database> setupDatabase1() async {
  var dbPath1 = r'lib\models\Users.db';
  var database1 = await databaseFactoryIo.openDatabase(dbPath1);
  return database1;
}

// Future<Database> setupDatabase2() async {
//   var dbPath2 = r'lib\models\Servers.db';
//   var database2 = await databaseFactoryIo.openDatabase(dbPath2);
//   return database2;
// }

//custom exceptions, can be expanded upon
class UserExistsException implements Exception {
  final String message = "The user already exists";
}

class AlreadyLoggedInException implements Exception {
  var message = "";
  AlreadyLoggedInException(username) {
    this.message = "The user $username is already logged in";
  }
}

class AlreadyLoggedOutException implements Exception {
  var message = "";
  AlreadyLoggedOutException(username) {
    this.message = "The user $username is already logged out";
  }
}

class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException(this.message);
}

class ServerNotFoundException implements Exception {
  final String message = "The server is not found";
}

class User {
  final String username;
  bool loggedIn;

  User({
    required this.username,
    this.loggedIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'loggedIn': loggedIn,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      loggedIn: map['loggedIn'],
    );
  }
}

//future implementation
// class Moderator implements User {

// }
class Message {
  final String contents;
  final User sender;

  Message(this.sender, this.contents);

  Map<String, dynamic> toMap() {
    return {
      'contents': contents,
      'sender': sender.toMap(),
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      User.fromMap(map['sender']),
      map['contents'],
    );
  }
}

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
    Server server, String sender, String channelName, String message) async {
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

//the actual binary will parse command line arguments and call these functions accordingly.
class ActualInterface {
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
      server.createMessage(senderName, channelName, message);

      await store.update(
        database,
        server.toMap(),
        finder: Finder(filter: Filter.byKey(serverRecord.key)),
      );

      print("Message sent successfully");
    }
  }

  Future<void> joinServer(String username, String serverName) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('servers');

    var userRecord = await store.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', username)),
    );

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var requiredUser = User.fromMap(userRecord.value);

      var serverRecord = await store.findFirst(
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

          await store.update(
            database,
            requiredServer.toMap(),
            finder: Finder(filter: Filter.byKey(serverRecord.key)),
          );

          print("User joined the server successfully");
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
}

//Where should send message in channel be implemented?

void main(List<String> arguments) {
  final parser = ArgParser();
  parser.addCommand('register');
  parser.addCommand('login');
  parser.addCommand('logout');
  parser.addCommand('create-server');
  parser.addCommand('add-channel');
  parser.addCommand('send-message');
  parser.addCommand('join-server');
  parser.addCommand('show-message');
  final results = parser.parse(arguments);
  final command = results.command?.name;

  final actualInterface = ActualInterface();

  // actualInterface.loginUser("hello");
  // actualInterface.loginUser("hello1");

  // actualInterface.logoutUser("hello1");
  //   actualInterface.createServer("hello1");

  try {
    switch (command) {
      case 'register':
        final username = results.command?.rest.first;
        if (username != null) {
          actualInterface.registerUser(username);
        } else {
          print('Username not provided');
        }
        break;
      case 'login':
        final username = results.command?.rest.first;
        if (username != null) {
          actualInterface.loginUser(username);
        } else {
          print('Username not provided');
        }
        break;
      case 'logout':
        final username = results.command?.rest.first;
        if (username != null) {
          actualInterface.logoutUser(username);
        } else {
          print('Username not provided');
        }
        break;
      case 'create-server':
        final serverName = results.command?.rest.first;
        if (serverName != null) {
          actualInterface.createServer(serverName);
        } else {
          print('Server name not provided');
        }
        break;
      case 'add-channel':
        final channelName = results.command?.rest[0];
        final category = results.command?.rest[1];
        final serverName = results.command?.rest[2];
        if (channelName != null && category != null && serverName != null) {
          actualInterface.addChannelToServer(channelName, category, serverName);
        } else {
          print('Incomplete parameters for adding channel');
        }
        break;

      case 'send-message':
        final senderName = results.command?.rest[0];
        final serverName = results.command?.rest[1];
        final channelName = results.command?.rest[2];
        final message = results.command?.rest[3];
        if (channelName != null &&
            senderName != null &&
            serverName != null &&
            message != null) {
          actualInterface.sendMessage(
              senderName, serverName, channelName, message);
        } else {
          print('null message');
        }
        break;
      case 'join-server':
        final username = results.command?.rest[0];
        final serverName = results.command?.rest[1];
        if (serverName != null && username != null) {
          actualInterface.joinServer(username, serverName);
          print('server joined succesfully');
        } else {
          print('Server name not provided');
        }
        break;
      case 'show-message':
        final serverName = results.command?.rest.first;
        if (serverName != null) {
          actualInterface.printMessages(serverName);
        } else {
          print('Server name not provided');
        }
        break;
      default:
        print('Invalid command! Please try again.');
        break;
    }
  } catch (e) {
    if (e is UserExistsException) {
      print('Error: ${e.message}');
    } else if (e is AlreadyLoggedInException) {
      print('Error: ${e.message}');
    } else if (e is AlreadyLoggedOutException) {
      print('Error: ${e.message}');
    } else if (e is UserNotFoundException) {
      print('Error: ${e.message}');
    } else if (e is ServerNotFoundException) {
      print('Error: ${e.message}');
    } else {
      print('Error: $e');
    }
  }
}
