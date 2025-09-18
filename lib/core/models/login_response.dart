class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;

  LoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: LoginData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data.toJson(),
  };
}

class LoginData {
  final User user;
  final String token;
  final String tokenType;
  final String secure;

  LoginData({
    required this.user,
    required this.token,
    required this.tokenType,
    required this.secure,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: (json['token'] ?? '').toString(),
      tokenType: (json['token_type'] ?? '').toString(),
      secure: (json['secure'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
    'token_type': tokenType,
    'secure': secure,
  };
}

class User {
  final int id;
  final int addedBy;
  final String employeeId;
  final String name;
  final String email;
  final bool emailVerifiedAt;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.addedBy,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? 0) as int,
      addedBy: (json['added_by'] ?? 0) as int,
      employeeId: (json['employeeId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      emailVerifiedAt: json['email_verified_at'] == true,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'added_by': addedBy,
    'employeeId': employeeId,
    'name': name,
    'email': email,
    'email_verified_at': emailVerifiedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
