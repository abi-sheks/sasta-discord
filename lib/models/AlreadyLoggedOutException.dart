class AlreadyLoggedOutException implements Exception {
  var message = "";
  AlreadyLoggedOutException(username) {
    this.message = "The user $username is already logged out";
  }
}
