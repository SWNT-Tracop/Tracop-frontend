class RegisterRequest {
  final String phone;
  final String role;
  final String fullName;
  final String? locale;
  final String deviceId;
  final String platform;
  final bool consentAccepted;
  final String consentVersion;

  const RegisterRequest({
    required this.phone,
    required this.role,
    required this.fullName,
    this.locale,
    required this.deviceId,
    required this.platform,
    required this.consentAccepted,
    required this.consentVersion,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'role': role,
        'fullName': fullName,
        if (locale != null) 'locale': locale,
        'deviceId': deviceId,
        'platform': platform,
        'consent': {
          'accepted': consentAccepted,
          'version': consentVersion,
        },
      };
}

class RequestOtpRequest {
  final String phone;

  const RequestOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class RequestOtpResponse {
  final String message;
  final String? botLink;

  const RequestOtpResponse({required this.message, this.botLink});

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) =>
      RequestOtpResponse(
        message: json['message'] as String,
        botLink: json['botLink'] as String?,
      );
}

class VerifyOtpRequest {
  final String phone;
  final String code;
  final String deviceId;
  final String platform;

  const VerifyOtpRequest({
    required this.phone,
    required this.code,
    required this.deviceId,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'code': code,
        'deviceId': deviceId,
        'platform': platform,
      };
}

class RefreshSessionRequest {
  final String refreshToken;
  final String deviceId;

  const RefreshSessionRequest({
    required this.refreshToken,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      };
}

class UpdateMeRequest {
  final String? fullName;
  final String? locale;

  const UpdateMeRequest({this.fullName, this.locale});

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (locale != null) 'locale': locale,
      };
}

class UpsertProviderProfileRequest {
  final String displayName;
  final String municipality;
  final String department;
  final double lat;
  final double lng;
  final String description;

  const UpsertProviderProfileRequest({
    required this.displayName,
    required this.municipality,
    required this.department,
    required this.lat,
    required this.lng,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'municipality': municipality,
        'department': department,
        'lat': lat,
        'lng': lng,
        'description': description,
      };
}
