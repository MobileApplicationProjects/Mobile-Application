import 'package:flutter/material.dart';

class CreateRoomDialog extends StatefulWidget {
  final Function(String name, int duration, List<String> invites) onSubmit;

  const CreateRoomDialog({super.key, required this.onSubmit});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  String _roomName = '';
  int _durationDays = 7;
  String _inviteInput = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF222222),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Create New Room',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[400]!)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a room name' : null,
                onSaved: (val) => _roomName = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _durationDays,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duration (Days)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[400]!)),
                ),
                items: [7, 14, 30].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value Days'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _durationDays = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Friend's Username or Email",
                  hintText: "Enter exact username or email",
                  hintStyle: const TextStyle(color: Colors.white30),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red[400]!)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'At least 1 friend required' : null,
                onSaved: (val) => _inviteInput = val!.trim(),
              ),
              const SizedBox(height: 8),
              const Text(
                'Separate multiple users with commas.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final invites = _inviteInput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              widget.onSubmit(_roomName, _durationDays, invites);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
          child: const Text('CREATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
