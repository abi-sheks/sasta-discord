
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
  var loggedIn = false;
  User(this.username);
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
  void registerUser(String username) {
    var userNames = allUsers.map((user) => user.username).toList();
    if (userNames.contains(username)) {
      throw UserExistsException();
    } else {
      allUsers.add(User(username));
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
    print("server created successfully");
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