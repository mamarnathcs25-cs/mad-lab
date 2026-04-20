import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/family_member.dart';

class FamilyManagerScreen extends StatefulWidget {
  const FamilyManagerScreen({super.key});

  @override
  State<FamilyManagerScreen> createState() => _FamilyManagerScreenState();
}

class _FamilyManagerScreenState extends State<FamilyManagerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Medicine Manager')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add family profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _relationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Father, Mother, Child...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isEmpty) {
                          return;
                        }

                        await controller.addProfile(
                          name: _nameController.text.trim(),
                          relationship: _relationshipController.text.trim(),
                        );
                        _nameController.clear();
                        _relationshipController.clear();
                      },
                      child: const Text('Add Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...controller.profiles.map(
            (profile) {
              final medicines = controller.medicinesForProfile(profile.id);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(profile.initials)),
                  title: Text(profile.name),
                  subtitle: Text(
                    '${profile.relationship.isEmpty ? 'Family member' : profile.relationship} - ${medicines.length} medicines tracked',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditDialog(profile),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(profile),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(FamilyMember profile) async {
    final controller = AppScope.of(context);
    final nameController = TextEditingController(text: profile.name);
    final relationshipController =
        TextEditingController(text: profile.relationship);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                await controller.updateProfile(
                  profileId: profile.id,
                  name: nameController.text.trim(),
                  relationship: relationshipController.text.trim(),
                );

                if (!mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    relationshipController.dispose();
  }

  Future<void> _confirmDelete(FamilyMember profile) async {
    final controller = AppScope.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete profile'),
          content: Text(
            'Delete ${profile.name}? Medicines and health records for this profile will also be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await controller.deleteProfile(profile.id);
    }
  }
}
