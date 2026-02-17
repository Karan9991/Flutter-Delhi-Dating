import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../providers.dart';
import '../../widgets/photo_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _educationController = TextEditingController();
  final _heightController = TextEditingController();

  bool _saving = false;
  bool _initialized = false;
  String _gender = 'Woman';
  String _lookingFor = 'Everyone';
  String _pronouns = 'Prefer not to say';
  final List<String> _photoUrls = [];
  final List<String> _interests = [];

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _educationController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _setInitialProfile(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _displayNameController.text = profile.displayName;
    _ageController.text = profile.age == 0 ? '' : profile.age.toString();
    _bioController.text = profile.bio;
    _gender = profile.gender.isEmpty ? _gender : profile.gender;
    _lookingFor = profile.lookingFor.isEmpty ? _lookingFor : profile.lookingFor;
    _pronouns = profile.pronouns?.isNotEmpty == true
        ? profile.pronouns!
        : _pronouns;
    _jobController.text = profile.jobTitle ?? '';
    _companyController.text = profile.company ?? '';
    _educationController.text = profile.education ?? '';
    _heightController.text = profile.heightCm?.toString() ?? '';
    _photoUrls
      ..clear()
      ..addAll(profile.photoUrls);
    _interests
      ..clear()
      ..addAll(profile.interests);
    _initialized = true;
  }

  Future<void> _addPhoto() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _saving = true);
    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadProfileImage(uid: auth.uid, file: File(file.path));
      setState(() => _photoUrls.add(url));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photoUrls.removeAt(index));
  }

  void _addInterest() {
    final text = _interestController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _interests.add(text);
      _interestController.clear();
    });
  }

  void _removeInterest(String interest) {
    setState(() => _interests.remove(interest));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoUrls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one photo.')));
      return;
    }

    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    final existingProfile = ref.read(userProfileProvider).value;
    setState(() => _saving = true);

    final profile = UserProfile(
      id: auth.uid,
      displayName: _displayNameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      bio: _bioController.text.trim(),
      gender: _gender,
      lookingFor: _lookingFor,
      location: 'Delhi',
      interests: _interests,
      photoUrls: _photoUrls,
      pronouns: _pronouns,
      jobTitle: _jobController.text.trim(),
      company: _companyController.text.trim(),
      education: _educationController.text.trim(),
      heightCm: int.tryParse(_heightController.text.trim()),
      createdAt: existingProfile?.createdAt,
    );

    try {
      await ref.read(firestoreServiceProvider).saveProfile(profile);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    _setInitialProfile(profileState.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoPicker(
                  photoUrls: _photoUrls,
                  onAddPhoto: _saving ? () {} : _addPhoto,
                  onRemovePhoto: _removePhoto,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (value) {
                    final age = int.tryParse(value ?? '');
                    if (age == null || age < 18) {
                      return 'You must be 18+';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bio is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Location is fixed to Delhi for all users.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Basics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobController,
                  decoration: const InputDecoration(labelText: 'Job title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(labelText: 'Education'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _pronouns,
                  decoration: const InputDecoration(labelText: 'Pronouns'),
                  items: const [
                    DropdownMenuItem(value: 'She/Her', child: Text('She/Her')),
                    DropdownMenuItem(value: 'He/Him', child: Text('He/Him')),
                    DropdownMenuItem(
                      value: 'They/Them',
                      child: Text('They/Them'),
                    ),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _pronouns = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'I am'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Woman',
                            child: Text('Woman'),
                          ),
                          DropdownMenuItem(value: 'Man', child: Text('Man')),
                          DropdownMenuItem(
                            value: 'Non-binary',
                            child: Text('Non-binary'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _lookingFor,
                        decoration: const InputDecoration(
                          labelText: 'Looking for',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Everyone',
                            child: Text('Everyone'),
                          ),
                          DropdownMenuItem(
                            value: 'Women',
                            child: Text('Women'),
                          ),
                          DropdownMenuItem(value: 'Men', child: Text('Men')),
                          DropdownMenuItem(
                            value: 'Non-binary',
                            child: Text('Non-binary'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _lookingFor = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _interests
                      .map(
                        (interest) => Chip(
                          label: Text(interest),
                          onDeleted: () => _removeInterest(interest),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _interestController,
                        decoration: const InputDecoration(
                          labelText: 'Add interest',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addInterest,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
