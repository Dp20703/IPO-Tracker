class Registrar {
  final int? id;
  final String name;
  final String url;

  Registrar({
    this.id,
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }

  factory Registrar.fromMap(Map<String, dynamic> map) {
    return Registrar(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  Registrar copyWith({
    int? id,
    String? name,
    String? url,
  }) {
    return Registrar(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }
}
