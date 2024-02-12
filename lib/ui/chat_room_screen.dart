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
    Key? key,
    required this.targetUser,
    required this.chatRoom,
    required this.userUser,
    required this.firebaseUser,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  TextEditingController messageCtr = TextEditingController();
  List<MessageModel> _messages = [];
  bool _isSending = false; // Flag to track if a message is being sent

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  void loadMessages() {
    FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .orderBy("createdon", descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages = snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    });
  }

  String formatDate(DateTime dateTime) {
    return DateFormat.yMMMMd().format(dateTime);
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void sendMessage(String chatRoomId, String currentUserId, String targetUserId,
      String msg, BuildContext context) async {
    if (_isSending) return; // Prevent multiple sends

    setState(() {
      _isSending = true;
    });

    MessageModel newMessage = MessageModel(
      messageId: uuid.v1(),
      sender: currentUserId,
      createdon: Timestamp.now(),
      text: msg,
      seen: false,
    );

    try {
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .collection("messages")
          .doc(newMessage.messageId)
          .set(newMessage.toMap());

      setState(() {
        _messages.insert(0, newMessage);
      });

      messageCtr.clear(); // Clear the message input field
    } catch (e) {
      print("Error sending message: $e");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }


  // Helper method to build a message row
  Widget buildMessageRow(MessageModel currentMessage) {
    return FutureBuilder<UserModel?>(
      future: getUserDetails(currentMessage.sender.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            UserModel? sender = snapshot.data;
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
                              sender?.fullname ?? '', // Use sender's name
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          SizedBox(
                              width: 2), // Add spacing between name and time
                          Text(
                            DateFormat.Hm()
                                .format(currentMessage.createdon!.toDate()),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height:
                              5), // Add spacing between name/time and message
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
          } else if (snapshot.hasError) {
            // Handle error if user details fetching fails
            return Text('Error fetching user details');
          }
        }
        // Return an empty container while loading
        return Container();
      },
    );
  }

  Future<UserModel?> getUserDetails(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      return UserModel.fromMap(userSnapshot.data() as Map<String, dynamic>);
    } else {
      return null;
    }
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
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        MessageModel currentMessage = _messages[index];

                        if (currentMessage.createdon != null) {
                          DateTime messageDate =
                              currentMessage.createdon!.toDate();
                          bool isLastMessage =
                              index == _messages.length - 1;
                          bool isDifferentDay =
                              !isSameDay(messageDate, DateTime.now()) &&
                                  !isLastMessage;
                          bool isDifferentNextDay = !isSameDay(
                                  messageDate,
                                  DateTime.now()
                                      .add(Duration(days: 1))) &&
                              !isLastMessage;

                          if (isDifferentDay) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  formatDate(messageDate),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700),
                                ),
                                buildMessageRow(currentMessage),
                              ],
                            );
                          } else if (isDifferentNextDay) {
                            return Column(
                              children: [
                                Text(
                                  "Today",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                buildMessageRow(currentMessage),
                              ],
                            );
                          }
                        }
                        return buildMessageRow(currentMessage);
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
                            sendMessage(
                              widget.chatRoom.chatroomid!,
                              widget.userUser.uid!,
                              widget.targetUser.uid!,
                              messageCtr.text.trim(),
                              context,
                            );
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
