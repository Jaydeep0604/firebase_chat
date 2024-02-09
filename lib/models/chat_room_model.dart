import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? chatroomid;
  String? title;
  Map<String, dynamic>? participants;
  String? lastMessage;
  List<dynamic>? users;
  Timestamp? createdon;

  ChatRoomModel({
    this.chatroomid,
    this.title,
    this.participants,
    this.lastMessage,
    this.users,
    this.createdon,
  });

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map['chatroomid'];
    title = map['title'];
    participants = map['participants'];
    lastMessage = map['lastMessage'];
    users = map['users'];
    createdon = map['createdon'];
  }

  Map<String, dynamic> toMap() {
    return {
      'chatroomid': chatroomid,
      'title': title,
      'participants': participants,
      'lastMessage': lastMessage,
      'users': users,
      'createdon': createdon,
    };
  }
}


