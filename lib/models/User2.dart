enum UserRole {
  admin,
  member,
}

class User {
  final String username;
  bool loggedIn;
  final String password;
  UserRole role; // Enum property to represent the user's role

  User({
    required this.username,
    this.loggedIn = false,
    required this.password,
    this.role = UserRole.member, // Default role is 'member'
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'loggedIn': loggedIn,
      'password': password,
      'role': role.toString(), // Serialize the role as a string
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      loggedIn: map['loggedIn'],
      password: map['password'],
      role: UserRole.values.firstWhere((r) => r.toString() == map['role'], orElse: () => UserRole.member),
    );
  }
}
