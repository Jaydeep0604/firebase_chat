import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ichat/allConstants/constants.dart';
import 'package:ichat/main.dart';
import 'package:ichat/models/chat_room_model.dart';
import 'package:ichat/models/user_model.dart';

class GroupScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const GroupScreen(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  TextEditingController searchCtr = TextEditingController();
  TextEditingController groupNameCtr = TextEditingController();
  List<UserModel> selectableUsers = [];
  Set<UserModel> selectedUsers = {};

  Future<ChatRoomModel?> getGroupGroupChatRoomModel(
      List<UserModel> targetUsers) async {
    ChatRoomModel chatRoom;

    List<String> targetUserIds = targetUsers.map((user) => user.uid!).toList();

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants", arrayContainsAny: targetUserIds)
        .get();

    if (snapshot.docs.length > 0) {
      // fetch existing chat
      print("chatroom already created");
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatRoom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);
      chatRoom = existingChatRoom;
    } else {
      // create a new one
      print("chatroom not created");
      List<String> participantIds = [widget.userModel.uid!, ...targetUserIds];
      Map<String, bool> participants = {};
      for (String id in participantIds) {
        participants[id] = true;
      }

      ChatRoomModel newChatRoom = ChatRoomModel(
        chatroomid: uuid.v1(),
        title: groupNameCtr.text,
        lastMessage: "",
        participants: participants,
        users: participantIds,
        createdon: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatRoom.chatroomid)
          .set(newChatRoom.toMap());
      chatRoom = newChatRoom;
      print("new chatroom created");
    }
    return chatRoom;
  }

  // Future<GroupChatRoomModel?> getGroupChatRoomModel(UserModel targetUser) async {
  //   GroupChatRoomModel chatRoom;
  //   QuerySnapshot snapshot = await FirebaseFirestore.instance
  //       .collection("chatrooms")
  //       .where("participants.${widget.userModel.uid}", isEqualTo: true)
  //       .where("participants.${targetUser.uid}", isEqualTo: true)
  //       .get();
  //   if (snapshot.docs.length > 0) {
  //     //fetch existing chat
  //     print("chatroom already created");
  //     var docData = snapshot.docs[0].data();
  //     GroupChatRoomModel existingChatRoom =
  //         GroupChatRoomModel.fromMap(docData as Map<String, dynamic>);
  //     chatRoom = existingChatRoom;
  //   } else {
  //     //create a new one
  //     print("chatroom not created");
  //     GroupChatRoomModel newChatRoom = GroupChatRoomModel(
  //       chatroomid: uuid.v1(),
  //       lastMessage: "",
  //       participants: {
  //         widget.userModel.uid.toString(): true,
  //         targetUser.uid.toString(): true
  //       },
  //       users: [widget.userModel.uid.toString(), targetUser.uid.toString()],
  //       createdon: Timestamp.now(),
  //     );
  //     await FirebaseFirestore.instance
  //         .collection("chatrooms")
  //         .doc(newChatRoom.chatroomid)
  //         .set(newChatRoom.toMap());
  //     chatRoom = newChatRoom;
  //     print("new chatroom created");
  //   }
  //   return chatRoom;
  // }

  // Future<GroupChatRoomModel?> createGroupChat() async {
  //   GroupChatRoomModel? GroupChatRoomModel = await getGroupChatRoomModel(searchedUser);
  //   if (GroupChatRoomModel != null) {
  //     Navigator.pop(context);
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) {
  //           return ChatRoomScreen(
  //             targetUser: searchedUser,
  //             userUser: widget.userModel,
  //             firebaseUser: widget.firebaseUser,
  //             chatRoom: GroupChatRoomModel,
  //           );
  //         },
  //       ),
  //     );
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchSelectableUsers();
  }

  void fetchSelectableUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection("users").get();
    if (snapshot.docs.isNotEmpty) {
      final List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != widget.userModel.uid)
          .toList();
      setState(() {
        selectableUsers = users;
      });
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
          key: Key("create group"),
          centerTitle: true,
          title: Text("New Group"),
          actions: [
            IconButton(
              onPressed: () {
                getGroupGroupChatRoomModel(selectedUsers.toList());
              },
              icon: Icon(Icons.check),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtr,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(hintText: "Search Members"),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: groupNameCtr,
                        decoration: InputDecoration(hintText: "Group name"),
                      ),
                    ),
                    
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                searchCtr.text.isEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: selectableUsers.length,
                          itemBuilder: (context, index) {
                            final user = selectableUsers[index];
                            final isSelected = selectedUsers.contains(user);

                            return ListTile(
                              onTap: () {
                                setState(() {
                                  if (!isSelected) {
                                    selectedUsers.add(user);
                                  } else {
                                    selectedUsers.remove(user);
                                  }
                                });
                              },
                              title: Text(user.fullname.toString()),
                              subtitle: Text(user.email.toString()),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.profilepic!),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: Colors.green)
                                  : null,
                            );
                          },
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: selectableUsers.length,
                          itemBuilder: (context, index) {
                            final user = selectableUsers[index];
                            final isSelected = selectedUsers.contains(user);

                            return ListTile(
                              onTap: () {
                                setState(() {
                                  if (!isSelected) {
                                    selectedUsers.add(user);
                                  } else {
                                    selectedUsers.remove(user);
                                  }
                                });
                              },
                              title: Text(user.fullname.toString()),
                              subtitle: Text(user.email.toString()),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.profilepic!),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: Colors.green)
                                  : null,
                            );
                          },
                        ),
                      ),
                SizedBox(height: 20),
                Text("Selected Users:"),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = selectedUsers.toList()[index];
                      return ListTile(
                        title: Text(user.fullname.toString()),
                        subtitle: Text(user.email.toString()),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profilepic!),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
