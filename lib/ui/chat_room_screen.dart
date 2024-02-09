import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ichat/allConstants/color_constants.dart';
import 'package:ichat/main.dart';
import 'package:ichat/models/chat_room_model.dart';
import 'package:ichat/models/message_model.dart';
import 'package:ichat/models/user_model.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatRoom;
  final UserModel userUser;
  final User firebaseUser;
  const ChatRoomScreen({
    super.key,
    required this.targetUser,
    required this.chatRoom,
    required this.userUser,
    required this.firebaseUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  TextEditingController messageCtr = TextEditingController();

  String formatDate(DateTime dateTime) {
    return DateFormat.yMMMMd().format(dateTime);
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void sendMessage() async {
    String msg = messageCtr.text.trim();
    messageCtr.clear();
    if (msg.isNotEmpty) {
      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: widget.userUser.uid,
        createdon: Timestamp.now(),
        text: msg,
        seen: false,
      );
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoom.chatroomid)
          .collection("messages")
          .doc(newMessage.messageId)
          .set(newMessage.toMap());

      widget.chatRoom.lastMessage = msg;
      print(widget.chatRoom.lastMessage);
      print(widget.chatRoom.chatroomid);
      print(widget.chatRoom.participants.toString());
      print(widget.chatRoom.users.toString());
      print(widget.chatRoom.title);
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoom.chatroomid)
          .set(widget.chatRoom.toMap());
      print("message sent");
    }
  }

  // Helper method to build a message row
  Widget buildMessageRow(MessageModel currentMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: (currentMessage.sender == widget.userUser.uid)
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: currentMessage.sender == widget.userUser.uid
                ? Colors.black87
                : Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentMessage.sender != widget.userUser.uid)
                    Text(
                      widget.targetUser.fullname.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  SizedBox(width: 2), // Add spacing between name and time
                  Text(
                    DateFormat.Hm().format(currentMessage.createdon!.toDate()),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5), // Add spacing between name/time and message
              Text(
                currentMessage.text.toString(),
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              widget.chatRoom.title == null || widget.chatRoom.title == ""
                  ? CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          NetworkImage(widget.targetUser.profilepic.toString()),
                    )
                  : Icon(Icons.group),
              SizedBox(
                width: 10,
              ),
              Text(
                widget.chatRoom.title == null || widget.chatRoom.title == ""
                    ? widget.targetUser.fullname.toString()
                    : widget.chatRoom.title.toString(),
              )
            ],
          ),
        ),
        body: SafeArea(
          child: Container(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("chatrooms")
                          .doc(widget.chatRoom.chatroomid)
                          .collection("messages")
                          .orderBy("createdon", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.active) {
                          if (snapshot.hasData) {
                            QuerySnapshot datasnapshot =
                                snapshot.data as QuerySnapshot;
                            DateTime currentDate = DateTime.now();
                            return ListView.builder(
                              reverse: true,
                              itemCount: datasnapshot.docs.length,
                              itemBuilder: (context, index) {
                                MessageModel currentMessage =
                                    MessageModel.fromMap(
                                        datasnapshot.docs[index].data()
                                            as Map<String, dynamic>);

                                // Check if the date has changed
                                if (currentMessage.createdon != null) {
                                  DateTime messageDate =
                                      currentMessage.createdon!.toDate();
                                  if (!isSameDay(messageDate, currentDate)) {
                                    currentDate = messageDate;
                                    return Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 10,
                                          ),
                                          color: Colors.grey.withOpacity(0.5),
                                          child: Text(
                                            formatDate(currentDate),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        buildMessageRow(currentMessage),
                                      ],
                                    );
                                  }
                                }
                                // If the date is the same, continue with the regular message row
                                return buildMessageRow(currentMessage);
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                  "An error occurred! Please check your internet connection."),
                            );
                          } else {
                            return Center(
                              child: Text("Say hi to your new friend"),
                            );
                          }
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                              color: AppColors.greyColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10)),
                          child: TextField(
                            controller: messageCtr,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Message"),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: AppColors.greyColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(50)),
                        child: IconButton(
                          onPressed: () {
                            sendMessage();
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
