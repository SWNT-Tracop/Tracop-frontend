class User {
  final String id;
  final String role;
  final String fullName;
  final String phone;
  final String status;
  final String locale;

  const User({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.locale,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        role: json['role'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        status: json['status'] as String,
        locale: json['locale'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'fullName': fullName,
        'phone': phone,
        'status': status,
        'locale': locale,
      };
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final DateTime refreshTokenExpiresAt;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessTokenExpiresIn: json['accessTokenExpiresIn'] as int,
        refreshTokenExpiresAt:
            DateTime.parse(json['refreshTokenExpiresAt'] as String),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessTokenExpiresIn': accessTokenExpiresIn,
        'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
        'user': user.toJson(),
      };
}
