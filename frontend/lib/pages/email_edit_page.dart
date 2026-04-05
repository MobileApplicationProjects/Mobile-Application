import 'package:flutter/material.dart';

class EmailEditPage extends StatefulWidget {
  final String currentEmail;

  const EmailEditPage({super.key, required this.currentEmail});

  @override
  State<EmailEditPage> createState() => _EmailEditPageState();
}

class _EmailEditPageState extends State<EmailEditPage> {
  bool _isLoading = false;
  bool _isEdited = false;

  final _newEmailCtrl = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newEmailCtrl.addListener(_onFieldChanged);
    _confirmEmailCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _newEmailCtrl.removeListener(_onFieldChanged);
    _confirmEmailCtrl.removeListener(_onFieldChanged);
    _newEmailCtrl.dispose();
    _confirmEmailCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  // [API MOCK] บันทึก Email อัปเดตเข้าระบบ
  Future<void> _saveEmail() async {
    final newEmail = _newEmailCtrl.text.trim();
    final confirmEmail = _confirmEmailCtrl.text.trim();

    if (newEmail.isEmpty || newEmail != confirmEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure emails match and are not empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: เรียกใช้ API อัปเดตอีเมลที่นี่ เช่น
    // final body = {'newEmail': newEmail};
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context, newEmail); // return email ให้อัปเดตหน้าแสดงผลก่อนหน้า
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        title: const Text('Email', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEdited)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          TextField(
                            controller: _newEmailCtrl,
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'New Email',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          TextField(
                            controller: _confirmEmailCtrl,
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Confirm Email',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
