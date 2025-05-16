import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String groupId;
  final String ownerId;
  final String groupName;
  final String groupCode;
  final List<String> members;

  Group({
    required this.groupId,
    required this.ownerId,
    required this.groupName,
    required this.groupCode,
    required this.members,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return Group(
      groupId: doc.id,
      ownerId: data?['ownerId'] ?? '',
      groupName: data?['groupName'] ?? 'Unnamed Group',
      groupCode: data?['groupCode'] ?? '',
      members: List<String>.from(data?['members'] ?? []),
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

  Group copyWith({
    String? groupId,
    String? ownerId,
    String? groupName,
    String? groupCode,
    List<String>? members,
  }) {
    return Group(
      groupId: groupId ?? this.groupId,
      ownerId: ownerId ?? this.ownerId,
      groupName: groupName ?? this.groupName,
      groupCode: groupCode ?? this.groupCode,
      members: members ?? this.members,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          ownerId == other.ownerId &&
          groupName == other.groupName &&
          groupCode == other.groupCode &&
          const ListEquality<String>().equals(members, other.members);

  @override
  int get hashCode =>
      groupId.hashCode ^
      ownerId.hashCode ^
      groupName.hashCode ^
      groupCode.hashCode ^
      members.hashCode;
}
