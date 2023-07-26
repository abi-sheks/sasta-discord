import 'package:args/args.dart';
import 'package:dart_application_1/dart_application_1.dart';
import 'package:dart_application_1/models/UserExistsException.dart';
import 'package:dart_application_1/models/UserNotFoundException.dart';
import 'package:dart_application_1/models/ServerNotFoundException.dart';
import 'package:dart_application_1/models/AlreadyLoggedInException.dart';
import 'package:dart_application_1/models/AlreadyLoggedOutException.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();
  parser.addCommand('register');
  parser.addCommand('login');
  parser.addCommand('logout');
  parser.addCommand('create-server');
  parser.addCommand('add-channel');
  parser.addCommand('send-message');
  parser.addCommand('join-server');
  parser.addCommand('show-message');
  parser.addCommand('show-dm');
  parser.addCommand('dm-message');

  final results = parser.parse(arguments);
  final command = results.command?.name;

  final actualInterface = DiscordAPI();

  // Use the server instance as needed
  try {
    switch (command) {
      case 'register':
        final username = results.command?.rest[0];
        final password = results.command?.rest[1];

        if (username != null && password != null) {
          actualInterface.registerUser(username, password);
        } else {
          print('Username not provided');
        }
        break;
      case 'login':
        final username = results.command?.rest[0];
        final password = results.command?.rest[1];
        if (username != null && password != null) {
          actualInterface.loginUser(username, password);
        } else {
          print('Username not provided');
        }
        break;
      case 'logout':
        final username = results.command?.rest[0];
        final password = results.command?.rest[1];
        if (username != null && password != null) {
          actualInterface.logoutUser(username, password);
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
        } else {
          print('Server name not provided');
        }
        break;
      case 'show-message':
        final serverName = results.command?.rest.first;
        if (serverName != null) {
          var server = actualInterface.getServer(serverName);
          server.showMessages();
        } else {
          print('Server name not provided');
        }
        break;
      case 'dm-message':
        final sender = results.command?.rest[0];
        final recipient = results.command?.rest[1];
        final message = results.command?.rest[2];
        if (sender != null && recipient != null && message != null) {
          actualInterface.sendDirectMessage(sender, recipient, message);
        }
        break;
      case 'show-dm':
        final sender = results.command?.rest[0];
        final recipient = results.command?.rest[1];
        if (sender != null && recipient != null) {
          actualInterface.printUserMessages(sender, recipient);
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
