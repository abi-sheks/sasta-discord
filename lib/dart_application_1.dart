import 'package:dart_application_1/models/Channel.dart';
import 'package:dart_application_1/models/user.dart';
import "package:dart_application_1/models/role.dart";
import 'package:dart_application_1/models/Server.dart';
import "package:dart_application_1/models/message.dart";
import 'package:sembast/sembast.dart';
import 'package:dart_application_1/helpers/db_setup.dart';
import "package:dart_application_1/models/ServerNotFoundException.dart";
import "package:dart_application_1/models/UserNotFoundException.dart";
import "package:dart_application_1/models/UserExistsException.dart";
import "package:dart_application_1/enums/permissions.dart";
import 'package:bcrypt/bcrypt.dart';

class DiscordAPI {
  var allUsers = <User>[];
  var allServers = <Server>[];
  DiscordAPI() {
    // Load servers from the database during object creation
    loadServers();
  }
  Future<void> registerUser(String username, String password) async {
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
      // Generate a salt for bcrypt
      var salt = BCrypt.gensalt();

      // Hash the password using bcrypt
      var hashedPassword = BCrypt.hashpw(password, salt);

      var user = User(
          username: username,
          password: hashedPassword); // Specify the named argument
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

  Future<void> loginUser(String username, String password) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('users');

    var userRecord = await store.findFirst(database,
        finder: Finder(filter: Filter.equals('username', username)));

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var user = User.fromMap(userRecord.value);

      final bool checkPassword = await BCrypt.checkpw(
          password, user.password); // Use the actual password parameter
      if (checkPassword) {
        if (user.loggedIn == false) {
          user.loggedIn = true;
          await store.update(database, user.toMap(),
              finder: Finder(filter: Filter.byKey(userRecord.key)));
          print("Logged in successfully");
        } else {
          print("User already logged in");
        }
      } else {
        print("Invalid password");
      }
    }
  }

  Future<void> logoutUser(String username, String password) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('users');

    var userRecord = await store.findFirst(database,
        finder: Finder(filter: Filter.equals('username', username)));

    if (userRecord == null) {
      throw UserNotFoundException(username);
    } else {
      var user = User.fromMap(userRecord.value);
      final bool checkPassword = await BCrypt.checkpw(
          password, user.password); // Use the actual password parameter

      if (checkPassword) {
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
  }

  Future<Server> createServer(String serverName, String user) async {
    var server = Server(serverName);
    var database = await setupDatabase1();

    var userStore = intMapStoreFactory.store('users');

    var userRecord = await userStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', user)),
    );
    allServers.add(server);
    if (userRecord != null) {
      var requiredUser = User.fromMap(userRecord.value);

      var store = await intMapStoreFactory.store('servers');
      server.admins.add(requiredUser);

      await store.add(database, server.toMap());
      print("huhu");

      print(server);
      print(allServers);
      print("Server created successfully");
    }
    return server;
  }

  Future<void> loadServers() async {
    var database = await setupDatabase1();
    var serverStore = intMapStoreFactory.store('servers');

    var serverRecords = await serverStore.find(database);

    print("Server records from the database: $serverRecords");

    // Clear the existing allServers list before adding the retrieved servers
    allServers.clear();

    allServers.addAll(
        serverRecords.map((record) => Server.fromMap(record.value)).toList());

    print("Loaded servers: $allServers");
  }

Future<Server> getServer(String name) async {
  var database = await setupDatabase1();
  var serverStore = intMapStoreFactory.store('servers');
  var serverRecord = await serverStore.findFirst(
    database,
    finder: Finder(filter: Filter.equals('name', name)),
  );

  if (serverRecord != null) {
    var requiredServer = Server.fromMap(serverRecord.value);
    return requiredServer;
  } else {
    throw Exception("Server not found");
  }
}


  Future<void> addChannelToServer(
    String channelName,
    String channelType,
    String serverName,
    String username,
  ) async {
    var database = await setupDatabase1();
    var store = intMapStoreFactory.store('servers');
    var userStore = intMapStoreFactory.store('users');
    var userRecord = await userStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', username)),
    );
    var serverRecord = await store.findFirst(
      database,
      finder: Finder(filter: Filter.equals('name', serverName)),
    );

    if (serverRecord == null) {
      throw ServerNotFoundException();
    } else {
      var server = Server.fromMap(serverRecord.value);
      if (userRecord != null) {
        var user = User.fromMap(userRecord.value);

        // Check if the user is an admin or moderator
        if (userIsAdminOrModerator(server, user)) {
          // Typecast the channelType string to the ChannelType enum
          ChannelType parsedChannelType;
          switch (channelType) {
            case 'general':
              parsedChannelType = ChannelType.general;
              break;
            case 'announcement':
              parsedChannelType = ChannelType.announcement;
              break;
            // Add more cases for other channel types if needed
            default:
              throw Exception("Invalid channel type.");
          }

          // Create a new channel based on the parsed channel type
          var newChannel = Channel(
            channelType: parsedChannelType,
            name: channelName,
          );

          server.channels.add(newChannel);
          server.createChannel(newChannel);
          // Update the server in the database
          await store.update(
            database,
            server.toMap(),
            finder: Finder(filter: Filter.byKey(serverRecord.key)),
          );

          print("Channel added to the server successfully");
        }
      } else {
        print("User does not have permission to add a channel to the server");
      }
    }
  }

// Future<void> updateDatabase(Database database, String serverName, String listName, List<User> listData) async {
//   var serverStore = intMapStoreFactory.store('servers');

//   // Find the server record in the database
//   var serverRecord = await serverStore.findFirst(
//     database,
//     finder: Finder(filter: Filter.equals('name', serverName)),
//   );

//   if (serverRecord == null) {
//     throw Exception('Server not found in the database');
//   } else {
//     var requiredServer = Server.fromMap(serverRecord.value);

//     // Update the specific list with the new list data
//     switch (listName) {
//       case 'members':
//         requiredServer.members = listData;
//         break;
//       case 'admins':
//         requiredServer.admins = listData;
//         break;
//       default:
//         throw Exception('Invalid list name');
//     }

//     // Update the server record in the database
//     await serverStore.update(
//       database,
//       requiredServer.toMap(),
//       finder: Finder(filter: Filter.equals('name', serverName)),
//     );

//     print('Database updated successfully');
//   }
// }
  Future<void> sendMessage(String senderName, String serverName,
      String channelName, String message) async {
    var database = await setupDatabase1();
    var serverStore = intMapStoreFactory.store('servers');

    var serverRecord = await serverStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('name', serverName)),
    );

    if (serverRecord == null) {
      throw ServerNotFoundException();
    } else {
      var updatedServer = Server.fromMap(serverRecord.value);
      User? requiredSender;

      for (var member in updatedServer.members) {
        if (member.username == senderName) {
          requiredSender = member;
          break;
        }
      }

      if (requiredSender == null) {
        for (var admin in updatedServer.admins) {
          if (admin.username == senderName) {
            requiredSender = admin;
            break;
          }
        }
      }

      if (requiredSender == null) {
        for (var moderator in updatedServer.moderators) {
          if (moderator.username == senderName) {
            requiredSender = moderator;
            break;
          }
        }
      }

      if (requiredSender == null) {
        throw UserNotFoundException("User has not joined this server");
      }

      var requiredChannel = updatedServer.channels.firstWhere(
        (channel) => channel.name == channelName,
        orElse: () => throw Exception("Channel does not exist on this server"),
      );

      print(requiredChannel.name);
      print(requiredChannel.channelType);
      if (requiredChannel.channelType == ChannelType.general) {
        if (userIsMember(updatedServer, requiredSender) ||
            userIsAdminOrModerator(updatedServer, requiredSender)) {
          await requiredChannel.createMessage(
              Message(requiredSender, message), channelName);
        }
      }

      if (requiredChannel.channelType == ChannelType.announcement) {
        if (userIsAdmin(updatedServer, requiredSender)) {
          await requiredChannel.createMessage(
              Message(requiredSender, message), channelName);
        } else {
          print("user has to be an admin to send messages to this channel");
        }
      }

      await serverStore.update(
        database,
        updatedServer.toMap(),
        finder: Finder(filter: Filter.byKey(serverRecord.key)),
      );

      print("Message sent successfully");
    }
  }

  bool userIsAdminOrModerator(Server server, User user) {
    return server.admins.any((admin) => admin.username == user.username) ||
        server.moderators
            .any((moderator) => moderator.username == user.username);
  }

  bool userIsMember(Server server, User user) {
    return server.members.any((member) => member.username == user.username);
  }

  bool userIsAdmin(Server server, User user) {
    return server.admins.any((admin) => admin.username == user.username);
  }

  Future<void> addMemberToServer(String requester, String serverName,
      String newmember, String permission) async {
    var database = await setupDatabase1();
    var userStore = intMapStoreFactory.store('users');
    var serverStore = intMapStoreFactory.store('servers');

    var userRecord1 = await userStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', requester)),
    );
    var userRecord2 = await userStore.findFirst(
      database,
      finder: Finder(filter: Filter.equals('username', newmember)),
    );

    if (userRecord1 == null || userRecord2 == null) {
      print("Make sure both users are registered");
    } else {
      var user1 = User.fromMap(userRecord1.value);
      if (!user1.loggedIn) {
        print("User not logged in");
      } else {
        var requiredUser1 = User.fromMap(userRecord1.value);
        var requiredUser2 = User.fromMap(userRecord2.value);

        var serverRecord = await serverStore.findFirst(
          database,
          finder: Finder(filter: Filter.equals('name', serverName)),
        );

        if (serverRecord == null) {
          throw ServerNotFoundException();
        } else {
          var requiredServer = Server.fromMap(serverRecord.value);
          print(requiredServer.admins);
          if (userIsAdminOrModerator(requiredServer, requiredUser1)) {
            switch (permission) {
              case 'admin':
                requiredServer.admins.add(requiredUser2);
                break;
              case 'moderator':
                requiredServer.moderators.add(requiredUser2);
                break;
              case 'member':
                requiredServer.members.add(requiredUser2);
                break;
            }

            await serverStore.update(
              database,
              requiredServer.toMap(),
              finder: Finder(filter: Filter.byKey(serverRecord.key)),
            );

            print(
                "User added to server successfully with permission: $permission");
          } else {
            throw Exception(
                "Only admins and moderators can add members to the server.");
          }
        }
      }
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
      // print("ashish...");
      // print(user);
      // print("angel...");
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
          // print("server hahahaha record");
          // print(serverRecord);
          // print("00lalalla");
          print(serverRecord.value);
          var requiredServer = Server.fromMap(serverRecord.value);
          // print("imsmsms");
          requiredServer.members.add(requiredUser);
          //requiredServer.admins.add(requiredUser);
          print(requiredServer.admins);

          await serverStore.update(
            database,
            requiredServer.toMap(),
            finder: Finder(filter: Filter.equals('name', serverName)),
          );
          print("User joined the server successfully");
        }
      }
    }
  }

  // void printMessages(String serverName) {
  //   var requiredServer = allServers.firstWhere(
  //     (server) => server.name == serverName,
  //     orElse: () => throw ServerNotFoundException(),
  //   );

  //   for (Channel channel in requiredServer.channels) {
  //     print("${channel.name} :");
  //     for (Message message in channel.messages) {
  //       print("${message.sender.username} : ${message.contents}");
  //     }
  //   }
  // }
  Future<void> createRole(
      String serverName, String? roleName, String? rolePerm) async {
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
      if (roleName == null) {
        throw Exception("Please provide a name for the role");
      }
      if (rolePerm == null) {
        server.addRole(Role(roleName, Perm.member));
        await store.update(database, server.toMap(),
            finder: Finder(filter: Filter.byKey(serverRecord.key)));
        return;
      }
      if (rolePerm == "moderator") {
        server.addRole(Role(roleName, Perm.moderator));
        await store.update(database, server.toMap(),
            finder: Finder(filter: Filter.byKey(serverRecord.key)));
        return;
      }
      server.addRole(Role(roleName, Perm.member));
      await store.update(database, server.toMap(),
          finder: Finder(filter: Filter.byKey(serverRecord.key)));
    }
  }

  Future<void> assignRole(
      String serverName, String roleName, String username) async {
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
      var reqRole = server.getRole(roleName);
      var reqUser = server.getMember(username);
      server.addUserToRole(reqRole, reqUser);
      await store.update(database, server.toMap(),
          finder: Finder(filter: Filter.byKey(serverRecord.key)));
    }
  }
}
