class User {
  final int? id;
  final String nombre;
  final String email;
  final String? password;
  final String? fotoUrl;

  User({
    this.id,
    required this.nombre,
    required this.email,
    this.password,
    this.fotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      fotoUrl: json['fotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nombre': nombre,
      'email': email,
    };
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    if (fotoUrl != null) {
      data['fotoUrl'] = fotoUrl;
    }
    return data;
  }
}