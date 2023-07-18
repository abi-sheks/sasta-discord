class AlreadyLoggedInException implements Exception {
  var message = "";
  AlreadyLoggedInException(username) {
    this.message = "The user $username is already logged in";
  }
}