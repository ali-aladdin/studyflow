class AppUser {
  final String email;
  final String username;
  final String uid;

  AppUser({
    required this.email,
    required this.username,
    required this.uid,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      username: map['username'],
      email: map['email'],
      uid: map['uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'uid': uid,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
  }) {
    return AppUser(
      email: email ?? this.email,
      username: username ?? this.username,
      uid: uid ?? this.uid,
    );
  }
}
