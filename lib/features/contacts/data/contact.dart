class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String note;
  final String? avatarPath;
  final int createdAt;
  final int updatedAt;

  const Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.note = '',
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        note: map['note'] as String? ?? '',
        avatarPath: map['avatar_path'] as String?,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'note': note,
        'avatar_path': avatarPath,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? note,
    String? avatarPath,
    int? createdAt,
    int? updatedAt,
  }) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        note: note ?? this.note,
        avatarPath: avatarPath ?? this.avatarPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
