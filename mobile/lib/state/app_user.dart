class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isDemo,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isDemo;

  AppUser copyWith({
    String? name,
    String? phone,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      isDemo: isDemo,
    );
  }

  Map<String, Object?> toMap() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "is_demo": isDemo,
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    final id = map["id"];
    final name = map["name"];
    final email = map["email"];
    final phone = map["phone"];
    final role = map["role"];
    final isDemo = map["is_demo"];
    if (id is! String ||
        name is! String ||
        email is! String ||
        phone is! String ||
        role is! String ||
        isDemo is! bool) {
      throw const FormatException(
          "El perfil local no tiene un formato válido.");
    }
    return AppUser(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isDemo: isDemo,
    );
  }
}
