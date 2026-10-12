class Account {
  final int? id;
  final String accountHolderName;
  final String accountNickname;
  final String panNumber;
  final String? dpId;
  final String? clientId;
  final String brokerName;
  final String? notes;
  final String createdAt;

  Account({
    this.id,
    required this.accountHolderName,
    required this.accountNickname,
    required this.panNumber,
    this.dpId,
    this.clientId,
    required this.brokerName,
    this.notes,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountHolderName': accountHolderName,
      'accountNickname': accountNickname,
      'panNumber': panNumber.toUpperCase(),
      'dpId': dpId,
      'clientId': clientId,
      'brokerName': brokerName,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      accountHolderName: map['accountHolderName'] as String? ?? '',
      accountNickname: map['accountNickname'] as String? ?? '',
      panNumber: map['panNumber'] as String? ?? '',
      dpId: map['dpId'] as String?,
      clientId: map['clientId'] as String?,
      brokerName: map['brokerName'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Account copyWith({
    int? id,
    String? accountHolderName,
    String? accountNickname,
    String? panNumber,
    String? dpId,
    String? clientId,
    String? brokerName,
    String? notes,
    String? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNickname: accountNickname ?? this.accountNickname,
      panNumber: panNumber ?? this.panNumber,
      dpId: dpId ?? this.dpId,
      clientId: clientId ?? this.clientId,
      brokerName: brokerName ?? this.brokerName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
