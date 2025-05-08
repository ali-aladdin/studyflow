import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String groupId;
  final String ownerId; // Firebase Auth UID of the owner
  final String groupName;
  final String groupCode;
  final List<String> members; // List of Firebase Auth UIDs

  Group({
    required this.groupId,
    required this.ownerId,
    required this.groupName,
    required this.groupCode,
    required this.members,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Group(
      groupId: doc.id,
      ownerId: data['ownerId'] ?? '',
      groupName: data['groupName'] ?? 'Unnamed Group',
      groupCode: data['groupCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'groupName': groupName,
      'groupCode': groupCode,
      'members': members,
    };
  }
}
