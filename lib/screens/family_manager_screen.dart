import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/screens/symptom_support_screen.dart';

class FamilyManagerScreen extends StatefulWidget {
  const FamilyManagerScreen({super.key});

  @override
  State<FamilyManagerScreen> createState() => _FamilyManagerScreenState();
}

class _FamilyManagerScreenState extends State<FamilyManagerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _ageController.dispose();
    _weightController.dispose();
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
                          age: int.tryParse(_ageController.text.trim()) ?? 0,
                          weightKg:
                              double.tryParse(_weightController.text.trim()) ??
                                  0,
                        );
                        _nameController.clear();
                        _relationshipController.clear();
                        _ageController.clear();
                        _weightController.clear();

                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile added')),
                        );
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
                    '${profile.relationship.isEmpty ? 'Family member' : profile.relationship} - Age ${profile.age} - ${profile.weightKg.toStringAsFixed(1)} kg - ${medicines.length} medicines tracked',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SymptomSupportScreen(profile: profile),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Symptom support',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SymptomSupportScreen(profile: profile),
                            ),
                          );
                        },
                        icon: const Icon(Icons.health_and_safety_outlined),
                      ),
                      IconButton(
                        onPressed: () => _openEditScreen(profile),
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

  Future<void> _openEditScreen(FamilyMember profile) async {
    final updated = await Navigator.of(context).push<FamilyMember>(
      MaterialPageRoute(
        builder: (_) => _EditFamilyProfileScreen(profile: profile),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    final controller = AppScope.of(context);

    try {
      await controller.updateProfile(
        profileId: updated.id,
        name: updated.name,
        relationship: updated.relationship,
        age: updated.age,
        weightKg: updated.weightKg,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update profile. Please try again.'),
        ),
      );
    }
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

class _EditFamilyProfileScreen extends StatefulWidget {
  const _EditFamilyProfileScreen({required this.profile});

  final FamilyMember profile;

  @override
  State<_EditFamilyProfileScreen> createState() =>
      _EditFamilyProfileScreenState();
}

class _EditFamilyProfileScreenState extends State<_EditFamilyProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _relationshipController =
        TextEditingController(text: widget.profile.relationship);
    _ageController = TextEditingController(text: widget.profile.age.toString());
    _weightController =
        TextEditingController(text: widget.profile.weightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                return;
              }

              Navigator.of(context).pop(
                widget.profile.copyWith(
                  name: _nameController.text.trim(),
                  relationship: _relationshipController.text.trim(),
                  age: int.tryParse(_ageController.text.trim()) ?? 0,
                  weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
