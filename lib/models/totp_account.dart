/// Data model representing non-sensitive TOTP account metadata.
/// TOTP secrets are stored separately in platform secure storage and excluded from this model.
class TotpAccount {
  final String id;
  final String issuer;
  final String accountName;
  final String algorithm; // e.g. "SHA1", "SHA256", "SHA512"
  final int digits; // e.g. 6 or 8
  final int period; // e.g. 30 or 60
  final DateTime createdAt;
  final DateTime updatedAt;

  const TotpAccount({
    required this.id,
    required this.issuer,
    required this.accountName,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  TotpAccount copyWith({
    String? issuer,
    String? accountName,
    DateTime? updatedAt,
  }) {
    return TotpAccount(
      id: id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      algorithm: algorithm,
      digits: digits,
      period: period,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'accountName': accountName,
      'algorithm': algorithm,
      'digits': digits,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TotpAccount.fromJson(Map<String, dynamic> json) {
    return TotpAccount(
      id: json['id'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'SHA1',
      digits: (json['digits'] as num?)?.toInt() ?? 6,
      period: (json['period'] as num?)?.toInt() ?? 30,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
