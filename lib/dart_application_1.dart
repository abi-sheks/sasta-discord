import 'package:args/args.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'dart:async';

Future<Database> setupDatabase() async {
  var dbPath = r'lib\models\hello.db';
  var database = await databaseFactoryIo.openDatabase(dbPath);
  return database;
}

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
}

class Channel {
  final String? category;
  final String name;
  var messages = <Message>[];
  Channel(this.category, this.name);
}

class Server {
  final String name;
  var channels = <Channel>[];
  var members = <User>[];
  //messages will also be stored here
  // var moderators = <Moderator>[];
  Server(this.name);
  void createChannel(Channel channel) {
    channels.add(channel);
    for (Channel channel in channels) {
      print("${channel.name}");
    }
  }

  void addMember(User member) {
    members.add(member);
  }

  bool isMember(String username) {
    var memberNames = members.map((e) => e.username).toList();
    if (memberNames.indexOf(username) == -1)
      return false;
    else
      return true;
  }

  void createMessage(String sender, String channelName, String message) {
    //guard clauses
    var requiredSender = members.firstWhere(
      (member) => member.username == sender,
      orElse: () =>
          throw new UserNotFoundException("User has not joined this server"),
    );
    var requiredChannel = channels.firstWhere(
      (channel) => channel.name == channelName,
      orElse: () =>
          throw new Exception("Channel does not exist on this server"),
    );
    requiredChannel.messages.add(new Message(requiredSender, message));
  }

  void showMessages() {
    for (Channel channel in channels) {
      print("${channel.name} : ");
      for (Message message in channel.messages) {
        print("${message.sender.username} : ${message.contents}");
      }
    }
  }
}

//the actual binary will parse command line arguments and call these functions accordingly.
class ActualInterface {
  var allUsers = <User>[];
  var allServers = <Server>[];
  Future<void> registerUser(String username) async {
    var database = await setupDatabase();
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

  void loginUser(String username) {
    var user = allUsers.firstWhere(
      (user) => user.username == username,
      orElse: () => throw UserNotFoundException("User does not exist"),
    );

    if (user.loggedIn) {
      throw AlreadyLoggedInException(username);
    } else {
      user.loggedIn = true;
      print("Logged in successfully");
    }
  }

  void logoutUser(String username) {
    var user = allUsers.firstWhere(
      (user) => user.username == username,
      orElse: () => throw UserNotFoundException("User does not exist"),
    );

    if (user.loggedIn) {
      user.loggedIn = false;
      print("Logged out successfully");
    } else {
      throw AlreadyLoggedOutException(username);
    }
  }

  void createServer(String serverName) {
    allServers.add(new Server(serverName));
  }

  void addChannelToServer(
      String channelName, String category, String serverName) {
    var server = allServers.firstWhere(
      (server) => server.name == serverName,
      orElse: () => throw ServerNotFoundException(),
    );

    server.createChannel(new Channel(category, channelName));
  }

  void sendMessage(String senderName, String serverName, String channelName,
      String message) {
    var server = allServers.firstWhere(
      (server) => server.name == serverName,
      orElse: () => throw ServerNotFoundException(),
    );
    server.createMessage(senderName, channelName, message);
  }

  void joinServer(String username, String serverName) {
    //find the user first.
    var requiredUser = allUsers.firstWhere(
      (user) => user.username == username,
      orElse: () => throw UserNotFoundException("User does not exist"),
    );
    var requiredServer = allServers.firstWhere(
      (server) => server.name == serverName,
      orElse: () => throw ServerNotFoundException(),
    );
    if (requiredServer.isMember(username))
      throw new Exception("The user is already a member of the server");
    else
      requiredServer.members.add(requiredUser);
  }

  void printMessages(String serverName) {
    var requiredServer = allServers.firstWhere(
      (server) => server.name == serverName,
      orElse: () => throw new ServerNotFoundException(),
    );
    requiredServer.showMessages();
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

  final results = parser.parse(arguments);
  final command = results.command?.name;

  final actualInterface = ActualInterface();

  actualInterface.registerUser("hello");
  // actualInterface.loginUser("hello");
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
