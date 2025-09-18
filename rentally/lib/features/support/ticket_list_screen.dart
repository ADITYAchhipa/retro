import 'package:flutter/material.dart';
import '../../services/support/ticket_service.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<SupportTicket> _tickets = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await TicketService.instance.getTickets();
      if (!mounted) return;
      setState(() {
        _tickets = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load tickets: $e';
      });
    }
  }

  Future<void> _createTicketDialog() async {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final bookingCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Support Ticket'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 3,
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bookingCtrl,
                  decoration: const InputDecoration(labelText: 'Booking ID (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await TicketService.instance.createTicket(
                subject: subjectCtrl.text.trim(),
                description: descCtrl.text.trim(),
                bookingId: bookingCtrl.text.trim().isEmpty ? null : bookingCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket created')));
    }
  }

  Future<void> _updateStatus(SupportTicket t) async {
    const statuses = TicketStatus.values;
    TicketStatus sel = t.status;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: DropdownButtonFormField<TicketStatus>(
          value: sel,
          items: statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (v) => sel = v ?? t.status,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok == true) {
      await TicketService.instance.updateStatus(t.id, sel);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
    }
  }

  Future<void> _deleteTicket(SupportTicket t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text('Delete "${t.subject}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TicketService.instance.deleteTicket(t.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicketDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_tickets.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.confirmation_number_outlined),
                            title: Text('No tickets yet'),
                            subtitle: Text('Create a ticket from Support Center'),
                          ),
                        )
                      else ..._tickets.map(
                        (t) => Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.confirmation_number_outlined,
                              color: t.status == TicketStatus.open
                                  ? Colors.orange
                                  : t.status == TicketStatus.resolved
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(t.subject),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Status: ${t.status.name} • Updated: ${t.updatedAt.toLocal()}'),
                                if (t.bookingId != null) Text('Booking: ${t.bookingId}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'status') {
                                  _updateStatus(t);
                                } else if (v == 'delete') {
                                  _deleteTicket(t);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'status', child: Text('Update Status')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
