import 'package:flutter/material.dart';
import '../../services/agency/agency_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ui_visibility_provider.dart';

class AgencyManagementScreen extends ConsumerStatefulWidget {
  const AgencyManagementScreen({super.key});

  @override
  ConsumerState<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends ConsumerState<AgencyManagementScreen> {
  List<AgencyMember> _members = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    // Hide bottom navigation while on Agency Management screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(immersiveRouteOpenProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    // Show the bottom navigation again when leaving
    ref.read(immersiveRouteOpenProvider.notifier).state = false;
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AgencyService.instance.getMembers();
      if (!mounted) return;
      setState(() {
        _members = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load members: $e';
      });
    }
  }

  Future<void> _inviteMemberDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'staff';
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Enter email';
                  if (!s.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'owner', child: Text('Co-owner')),
                ],
                onChanged: (v) => role = v ?? 'staff',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await AgencyService.instance.inviteMember(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                role: role,
              );
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent')));
    }
  }

  Future<void> _changeRole(AgencyMember m) async {
    String newRole = m.role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: DropdownButtonFormField<String>(
          value: newRole,
          items: const [
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
            DropdownMenuItem(value: 'manager', child: Text('Manager')),
            DropdownMenuItem(value: 'owner', child: Text('Co-owner')),
          ],
          onChanged: (v) => newRole = v ?? m.role,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok == true) {
      await AgencyService.instance.updateRole(m.id, newRole);
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated')));
    }
  }

  Future<void> _removeMember(AgencyMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${m.name} from agency?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AgencyService.instance.removeMember(m.id);
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agency Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _inviteMemberDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Invite'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Members', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_members.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.group_outlined),
                            title: Text('No members yet'),
                            subtitle: Text('Invite co-owners and staff to collaborate'),
                          ),
                        )
                      else ..._members.map((m) => Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text(_initials(m.name))),
                              title: Text(m.name),
                              subtitle: Text(m.email),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'role') {
                                    _changeRole(m);
                                  } else if (v == 'remove') {
                                    _removeMember(m);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'role',
                                    child: Row(children: [Icon(Icons.badge_outlined), SizedBox(width: 8), Text('Change Role')]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Remove')]),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              dense: false,
                              subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                              tileColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              
                            ),
                          )),
                      const SizedBox(height: 16),
                      Text('Roles & Permissions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.manage_accounts),
                          title: Text('Configure access levels'),
                          subtitle: Text('Define what managers and staff can do'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Business Verification', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.verified),
                          title: Text('Verify your agency'),
                          subtitle: Text('Upload documents to unlock features'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    return (parts[0].isNotEmpty ? parts[0][0] : '?').toUpperCase() + (parts[1].isNotEmpty ? parts[1][0] : '?').toUpperCase();
  }
}
