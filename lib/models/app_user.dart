/// 로컬 회원 계정 모델
class AppUser {
  final String id; // 내부 고유 id (이메일 기반)
  final String email;
  final String nickname;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
    id: map['id'] as String,
    email: map['email'] as String,
    nickname: (map['nickname'] as String?) ?? '',
    passwordHash: map['passwordHash'] as String,
    salt: map['salt'] as String,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
