/// The authenticated user profile, persisted locally and mirrored to Firestore.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name = '',
    this.photoUrl,
    this.emailVerified = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;

  String get displayName => name.trim().isNotEmpty ? name.trim() : email.split('@').first;
  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({String? name, String? photoUrl, bool? emailVerified}) => AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        emailVerified: emailVerified ?? this.emailVerified,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'emailVerified': emailVerified,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: (j['email'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        photoUrl: j['photoUrl'] as String?,
        emailVerified: (j['emailVerified'] as bool?) ?? false,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}
