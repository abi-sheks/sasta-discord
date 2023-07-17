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