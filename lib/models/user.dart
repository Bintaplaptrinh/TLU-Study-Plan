class User {
  final String studentId;
  final String fullName;
  final String email;
  final String? profileImageUrl;

  User({
    required this.studentId,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
  });
}
