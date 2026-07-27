import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/services/firebase_storage_service.dart';
import '../../../../core/services/media_picker_service.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../../user/presentation/providers/current_user_provider.dart';
import '../../domain/services/velix_qr_payload.dart';
import '../widgets/friends_statistics_card.dart';
import '../widgets/profile_avatar.dart';

/// Editable profile fields opened from the Profile Details menu item.
class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _tagLineController = TextEditingController();
  final _nameController = TextEditingController();
  bool _controllersReady = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _tagLineController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _syncControllers(UserEntity user) {
    if (_controllersReady) return;
    _tagLineController.text = user.about;
    _nameController.text = user.name;
    _controllersReady = true;
  }

  Future<void> _persist(UserEntity updated) async {
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateCurrentUser(updated);
      await ref.read(currentUserProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveTagLine(UserEntity user) async {
    final next = _tagLineController.text.trim();
    if (next == user.about.trim()) return;
    await _persist(user.copyWith(about: next, updatedAt: DateTime.now()));
  }

  Future<void> _saveName(UserEntity user) async {
    final next = _nameController.text.trim();
    if (next.isEmpty || next == user.name.trim()) return;
    await _persist(user.copyWith(name: next, updatedAt: DateTime.now()));
  }

  Future<void> _editPhoto(UserEntity user) async {
    final File? file;
    try {
      file = await MediaPickerService.pickImageFromGallery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await FirebaseStorageService().uploadFile(
        path: 'users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        file: file,
        contentType: 'image/jpeg',
        metadata: SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaderId': user.uid},
        ),
      );
      await _persist(user.copyWith(photoUrl: url, updatedAt: DateTime.now()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _copyVelixId(String handle) async {
    await Clipboard.setData(ClipboardData(text: handle));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Velix ID copied')),
    );
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentUserProvider);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 600 ? 48.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Unable to load profile.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  'Sign in to view profile details.',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            _syncControllers(user);
            final handle = VelixQrPayload.displayHandle(user.velixId);

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ProfileAvatar(
                              displayName: user.name,
                              photoUrl: user.photoUrl.trim().isEmpty
                                  ? null
                                  : user.photoUrl,
                            ),
                            if (_uploadingPhoto)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: (_saving || _uploadingPhoto)
                              ? null
                              : () => _editPhoto(user),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Edit Profile Photo'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const FriendsStatisticsCard(),
                      const SizedBox(height: 20),
                      Text(
                        'Tag Line',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagLineController,
                        enabled: !_saving,
                        maxLines: 2,
                        maxLength: 120,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => _saveTagLine(user),
                        onSubmitted: (_) => _saveTagLine(user),
                        decoration: InputDecoration(
                          hintText: 'Add a tag line…',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Velix User Name',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        enabled: !_saving,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => _saveName(user),
                        onSubmitted: (_) => _saveName(user),
                        decoration: InputDecoration(
                          hintText: 'Your display name',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Velix User ID',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: colorScheme.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  handle.isEmpty ? '—' : handle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy',
                                onPressed: handle.isEmpty
                                    ? null
                                    : () => _copyVelixId(handle),
                                icon: Icon(
                                  Icons.copy_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: _saving ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
