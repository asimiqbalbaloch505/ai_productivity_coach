class AuthFormData {
  final String email;
  final String password;
  final String? fullName;

  const AuthFormData({
    required this.email,
    required this.password,
    this.fullName,
  });
}
