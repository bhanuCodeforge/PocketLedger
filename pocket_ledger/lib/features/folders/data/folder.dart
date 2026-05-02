class Folder {
  final String id;
  final String name;
  final String? parentId;
  final String color;
  final String icon;
  final String status;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  List<Folder> children;
  int transactionCount;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.color = '#607D8B',
    this.icon = 'folder',
    this.status = 'active',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
    this.transactionCount = 0,
  });

  bool get isActive => status == 'active';
  bool get isRoot => parentId == null;

  factory Folder.fromMap(Map<String, dynamic> map) => Folder(
        id: map['id'] as String,
        name: map['name'] as String,
        parentId: map['parent_id'] as String?,
        color: map['color'] as String? ?? '#607D8B',
        icon: map['icon'] as String? ?? 'folder',
        status: map['status'] as String? ?? 'active',
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'color': color,
        'icon': icon,
        'status': status,
        'sort_order': sortOrder,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    String? color,
    String? icon,
    String? status,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    List<Folder>? children,
  }) =>
      Folder(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId ?? this.parentId,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        status: status ?? this.status,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        children: children ?? this.children,
      );
}
