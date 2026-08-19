import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _nameKey = 'profile_name';
  static const String _imageKey = 'profile_image';

  final ImagePicker _imagePicker = ImagePicker();

  String _name = 'Fitness User';
  String? _imagePath;

  bool _isLoading = true;
  bool _isSavingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final savedName = preferences.getString(_nameKey);
      final savedImage = preferences.getString(_imageKey);

      String? validImagePath;

      if (savedImage != null && savedImage.trim().isNotEmpty) {
        final imageFile = File(savedImage);

        if (await imageFile.exists()) {
          validImagePath = savedImage;
        } else {
          await preferences.remove(_imageKey);
        }
      }

      if (!mounted) return;

      setState(() {
        _name = savedName != null && savedName.trim().isNotEmpty
            ? savedName.trim()
            : 'Fitness User';

        _imagePath = validImagePath;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Profile loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isSavingImage) {
      return;
    }

    try {
      setState(() {
        _isSavingImage = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
        requestFullMetadata: false,
      );

      if (image == null) {
        if (!mounted) return;

        setState(() {
          _isSavingImage = false;
        });

        return;
      }

      final sourceFile = File(image.path);

      if (!await sourceFile.exists()) {
        throw Exception('Selected image does not exist.');
      }

      final appDirectory = await getApplicationDocumentsDirectory();

      final profileDirectory = Directory('${appDirectory.path}/profile');

      if (!await profileDirectory.exists()) {
        await profileDirectory.create(recursive: true);
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final savedPath = '${profileDirectory.path}/$fileName';

      final oldPath = _imagePath;

      await sourceFile.copy(savedPath);

      final savedFile = File(savedPath);

      if (!await savedFile.exists()) {
        throw Exception('Could not save profile image.');
      }

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_imageKey, savedPath);

      if (oldPath != null && oldPath.isNotEmpty && oldPath != savedPath) {
        final oldFile = File(oldPath);

        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (error) {
            debugPrint('Old profile image delete error: $error');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _imagePath = savedPath;
        _isSavingImage = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Profile image error: $error');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isSavingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the profile picture.')),
      );
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      final oldPath = _imagePath;

      final preferences = await SharedPreferences.getInstance();

      await preferences.remove(_imageKey);

      if (oldPath != null && oldPath.isNotEmpty) {
        final oldFile = File(oldPath);

        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      if (!mounted) return;

      setState(() {
        _imagePath = null;
      });
    } catch (error) {
      debugPrint('Profile image removal error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove profile picture.')),
      );
    }
  }

  Future<void> _showImageOptions() async {
    if (_isSavingImage) {
      return;
    }

    if (_imagePath == null) {
      await _pickProfileImage();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Change profile picture'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickProfileImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove profile picture'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _removeProfileImage();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return EditNameDialog(
          currentName: _name == 'Fitness User' ? '' : _name,
        );
      },
    );

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    final cleanName = newName.trim();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_nameKey, cleanName);

    if (!mounted) return;

    setState(() {
      _name = cleanName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Text(
            'Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Manage your personal information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              decoration: TextDecoration.none,
            ),
          ),

          const SizedBox(height: 28),

          _buildProfileCard(context),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Profile Picture', Icons.photo_outlined),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: _buildIconContainer(
                context,
                Icons.photo_library_outlined,
              ),
              title: const Text(
                'Change profile picture',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              subtitle: Text(
                _imagePath == null
                    ? 'Choose a picture from your gallery'
                    : 'Change or remove your current picture',
                style: const TextStyle(decoration: TextDecoration.none),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showImageOptions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.40),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(child: _buildProfileImage()),
                ),

                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: _isSavingImage
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: colors.primary,
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: GestureDetector(
              onTap: _editName,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Fitness Tracker member',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final path = _imagePath;

    if (path == null || path.isEmpty) {
      return const Icon(Icons.person_rounded, color: Colors.white, size: 44);
    }

    final file = File(path);

    if (!file.existsSync()) {
      return const Icon(Icons.person_rounded, color: Colors.white, size: 44);
    }

    return Image.file(
      file,
      key: ValueKey(path),
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.person_rounded, color: Colors.white, size: 44);
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildIconContainer(BuildContext context, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 21),
    );
  }
}

class EditNameDialog extends StatefulWidget {
  final String currentName;

  const EditNameDialog({super.key, required this.currentName});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Name',
        style: TextStyle(decoration: TextDecoration.none),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Your name',
          hintText: 'Enter your name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text(
            'Save',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
      ],
    );
  }
}
