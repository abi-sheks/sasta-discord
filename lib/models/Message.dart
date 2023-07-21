import "package:dart_application_1/models/user.dart";

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