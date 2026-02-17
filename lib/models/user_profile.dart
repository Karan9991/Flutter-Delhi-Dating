import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.bio,
    required this.gender,
    required this.lookingFor,
    required this.location,
    required this.interests,
    required this.photoUrls,
    this.pronouns,
    this.jobTitle,
    this.company,
    this.education,
    this.heightCm,
    this.lastActive,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final int age;
  final String bio;
  final String gender;
  final String lookingFor;
  final String location;
  final List<String> interests;
  final List<String> photoUrls;
  final String? pronouns;
  final String? jobTitle;
  final String? company;
  final String? education;
  final int? heightCm;
  final DateTime? lastActive;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? displayName,
    int? age,
    String? bio,
    String? gender,
    String? lookingFor,
    String? location,
    List<String>? interests,
    List<String>? photoUrls,
    String? pronouns,
    String? jobTitle,
    String? company,
    String? education,
    int? heightCm,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      photoUrls: photoUrls ?? this.photoUrls,
      pronouns: pronouns ?? this.pronouns,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      education: education ?? this.education,
      heightCm: heightCm ?? this.heightCm,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedLocation = location.trim().isEmpty
        ? 'Delhi'
        : location.trim();
    return {
      'displayName': displayName,
      'age': age,
      'bio': bio,
      'gender': gender,
      'lookingFor': lookingFor,
      'location': normalizedLocation,
      'interests': interests,
      'photoUrls': photoUrls,
      'pronouns': pronouns,
      'jobTitle': jobTitle,
      'company': company,
      'education': education,
      'heightCm': heightCm,
      'lastActive': lastActive == null ? null : Timestamp.fromDate(lastActive!),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawLocation = (data['location'] ?? '') as String;
    return UserProfile(
      id: doc.id,
      displayName: (data['displayName'] ?? '') as String,
      age: (data['age'] is num) ? (data['age'] as num).toInt() : 0,
      bio: (data['bio'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      lookingFor: (data['lookingFor'] ?? '') as String,
      location: rawLocation.trim().isEmpty ? 'Delhi' : rawLocation,
      interests: List<String>.from(data['interests'] ?? const []),
      photoUrls: List<String>.from(data['photoUrls'] ?? const []),
      pronouns: data['pronouns'] as String?,
      jobTitle: data['jobTitle'] as String?,
      company: data['company'] as String?,
      education: data['education'] as String?,
      heightCm: data['heightCm'] is num
          ? (data['heightCm'] as num).toInt()
          : null,
      lastActive: _toDateTime(data['lastActive']),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
