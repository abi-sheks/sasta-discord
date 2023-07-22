class User {
  final String username;
  bool loggedIn;
  final String password;

  User({
    required this.username,
    this.loggedIn = false,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'loggedIn': loggedIn,
      'password': password,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      loggedIn: map['loggedIn'],
      password: map['password'],
    );
  }
}
