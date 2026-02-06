class UserProfile {
  final String fullName;
  final String email;
  final int points;
  final double co2Saved;
  final int itemsRecycled;
  final double treesSaved;

  UserProfile({
    required this.fullName,
    required this.email,
    required this.points,
    required this.co2Saved,
    this.itemsRecycled = 0,
    this.treesSaved = 0.0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      points: json['points'] ?? 0,
      co2Saved: (json['co2_saved'] ?? 0).toDouble(),
      itemsRecycled: json['items_recycled'] ?? 0,
      treesSaved: (json['trees_saved'] ?? 0).toDouble(),
    );
  }
}