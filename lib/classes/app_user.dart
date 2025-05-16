class AppUser {
  final String uid;
  final String email;
  final String username;
  final List<String> joinedGroupIds;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.joinedGroupIds,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      joinedGroupIds: List<String>.from(map['joinedGroupIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'joinedGroupIds': joinedGroupIds,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    List<String>? joinedGroupIds,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      joinedGroupIds: joinedGroupIds ?? this.joinedGroupIds,
    );
  }
}
