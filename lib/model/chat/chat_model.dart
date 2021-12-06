import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ChatType { One_To_One, Group }

class ChatsModel extends Equatable {
  final List<ChatModel> chats;
  final DocumentSnapshot? firstDoc;
  final DocumentSnapshot? lastDoc;

  const ChatsModel({required this.chats, this.firstDoc, this.lastDoc});

  @override
  List<Object?> get props => [chats, lastDoc];
}

class ChatModel extends Equatable {
  final String chatId;
  final ChatType type;
  final String? groupName; // required for group chat
  final String? groupDescription; // required for group chat
  final String? groupImage; // required for group chat
  final String? groupCreatedBy;
  final List<String> members;
  final DateTime creationDate;
  final DateTime updateDate;
  final String lastMessage;
  final String? senderId;

  const ChatModel({
    required this.chatId,
    required this.type,
    this.groupName,
    this.groupDescription,
    this.groupImage,
    this.groupCreatedBy,
    required this.creationDate,
    required this.lastMessage,
    this.senderId,
    required this.members,
    required this.updateDate,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data) {
    final members = <String>[];
    for (String userId in data['members']) members.add(userId);

    return ChatModel(
      chatId: data["chatId"] as String,
      type: getChatTpe(data["type"] as String),
      lastMessage: data["lastMessage"] as String,
      members: members,
      groupName: data['groupName'] as String? ?? "",
      groupDescription: data['groupDescription'] as String? ?? "",
      groupImage: data['groupImage'] as String? ?? "",
      groupCreatedBy: data['groupCreatedBy'] as String? ?? "",
      senderId: data['senderId'] as String? ?? "",
      creationDate: DateTime.parse(data['creationDate'] as String).toLocal(),
      updateDate: DateTime.parse(data['updateDate'] as String).toLocal(),
    );
  }

  ChatModel copyWith({String? image, String? subject, String? desc}) {
    return ChatModel(
      chatId: chatId,
      type: type,
      groupName: subject ?? groupName,
      groupDescription: desc ?? groupDescription,
      groupImage: image ?? groupImage,
      groupCreatedBy: groupCreatedBy,
      creationDate: creationDate,
      lastMessage: lastMessage,
      members: members,
      senderId: senderId,
      updateDate: updateDate,
    );
  }

  static ChatType getChatTpe(final String type) {
    switch (type) {
      case "group":
        return ChatType.Group;
      default:
        return ChatType.One_To_One;
    }
  }

  // only available to one to one chat
  // only available to get the other userId
  String? getReceipient(final String currentuserId) {
    if (type == ChatType.One_To_One) {
      final users = members.toList();
      users.remove(currentuserId);
      return users.first;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "chatId": chatId,
      "type": "group",
      "lastMessage": lastMessage,
      "groupName": groupName,
      "groupDescription": "",
      "groupImage": groupImage ?? "",
      "groupCreatedBy": groupCreatedBy,
      "creationDate": creationDate.toUtc().toIso8601String(),
      "updateDate": creationDate.toUtc().toIso8601String(),
      "members": members,
    };
  }

  static Map<String, dynamic> toSubjectMap(String subject) {
    return <String, dynamic>{"groupName": subject};
  }

  static Map<String, dynamic> toDescriptionMap(String description) {
    return <String, dynamic>{"groupDescription": description};
  }

  static Map<String, dynamic> toGroupImageMap(String groupImageURL) {
    return <String, dynamic>{"groupImage": groupImageURL};
  }

  @override
  List<Object?> get props => [
        chatId,
        type,
        groupName,
        groupDescription,
        groupImage,
        groupCreatedBy,
        creationDate,
        lastMessage,
        members,
        updateDate,
        senderId,
      ];
}
