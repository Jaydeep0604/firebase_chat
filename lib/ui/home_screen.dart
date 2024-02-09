import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ichat/allConstants/color_constants.dart';
import 'package:ichat/helper/firebase_helper.dart';
import 'package:ichat/models/chat_room_model.dart';
import 'package:ichat/models/user_model.dart';
import 'package:ichat/ui/chat_room_screen.dart';
import 'package:ichat/ui/group_chat_screen.dart';
import 'package:ichat/ui/login_screen.dart';
import 'package:ichat/ui/realtime_databse/realtime_data_screen.dart';
import 'package:ichat/ui/search_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;
  HomeScreen({super.key, required this.userModel, required this.firebaseUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("Chat App"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () async {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RealtimeDatabaseScreen();
                }));
              },
              icon: Icon(Icons.drive_file_rename_outline_sharp)),
          SizedBox(
            width: 10,
          ),
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) {
                  return LoginScreen();
                }));
              },
              icon: Icon(Icons.exit_to_app))
        ],
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SearchScreen(
                          userModel: widget.userModel,
                          firebaseUser: widget.firebaseUser);
                    }));
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        Icon(Icons.search),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(child: Text("Search User")),
                        SizedBox(
                          width: 20,
                        ),
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: AppColors.themeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("chatrooms")
                      .where("users", arrayContains: widget.userModel.uid)
                      .orderBy("createdon")
                      .where("participants.${widget.userModel.uid}",
                          isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot chatRoomSnapshot =
                            snapshot.data as QuerySnapshot;
                        return ListView.builder(
                          itemCount: chatRoomSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                                chatRoomSnapshot.docs[index].data()
                                    as Map<String, dynamic>);
                            Map<String, dynamic> participants =
                                chatRoomModel.participants!;
                            List<String> participantsKey =
                                participants.keys.toList();
                            participantsKey.remove(widget.userModel.uid);
                            return FutureBuilder(
                              future: FirebaseHelper.getUserModelById(
                                  participantsKey[0]),
                              builder: (context, userData) {
                                if (userData.connectionState ==
                                    ConnectionState.done) {
                                  if (userData.data != null) {
                                    UserModel targetUser =
                                        userData.data as UserModel;
                                    return ListTile(
                                      onTap: () {
                                        print(
                                            "+++++${chatRoomModel.title}------");
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return ChatRoomScreen(
                                            chatRoom: chatRoomModel,
                                            firebaseUser: widget.firebaseUser,
                                            userUser: widget.userModel,
                                            targetUser: targetUser,
                                          );
                                        }));
                                      },
                                      leading: chatRoomModel.title == "" ||
                                              chatRoomModel.title == null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  targetUser.profilepic
                                                      .toString()),
                                            )
                                          : Icon(Icons.group),
                                      title: Text(chatRoomModel.title == "" ||
                                              chatRoomModel.title == null
                                          ? targetUser.fullname.toString()
                                          : chatRoomModel.title.toString()),
                                      subtitle: chatRoomModel.lastMessage
                                                  .toString() !=
                                              ""
                                          ? Text(chatRoomModel.lastMessage
                                              .toString())
                                          : Text("Say hi to your new friend!"),
                                    );
                                  } else {
                                    return Container();
                                  }
                                } else {
                                  return Container();
                                }
                              },
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(snapshot.error.toString()),
                        );
                      } else {
                        return Center(
                          child: Text("No Chats"),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.group),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupScreen(
                userModel: widget.userModel, firebaseUser: widget.firebaseUser),
          ),
        ),
      ),
    );
  }
}
