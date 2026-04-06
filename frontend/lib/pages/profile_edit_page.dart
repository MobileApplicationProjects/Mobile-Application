import 'package:flutter/material.dart';
import 'email_edit_page.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  bool _isLoading = true;
  bool _isEdited = false;

  String _email = '';
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();

    _firstNameCtrl.addListener(_onFieldChanged);
    _lastNameCtrl.addListener(_onFieldChanged);
    _address1Ctrl.addListener(_onFieldChanged);
    _address2Ctrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _firstNameCtrl.removeListener(_onFieldChanged);
    _lastNameCtrl.removeListener(_onFieldChanged);
    _address1Ctrl.removeListener(_onFieldChanged);
    _address2Ctrl.removeListener(_onFieldChanged);
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_isEdited && !_isLoading) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  // [API MOCK] โหลดข้อมูล Profile
  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);

    // TODO: เรียกใช้ API GET /user/profile/edit
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _email = 'dianne@gmail.com';
      _firstNameCtrl.text = 'Dianne';
      _lastNameCtrl.text = 'West';
      _address1Ctrl.text = 'Phutthamonthon';
      _address2Ctrl.text = 'Nakhon Pathom';
      _isLoading = false;
      _isEdited = false; // reset after load
    });
  }

  // [API MOCK] บันทึกข้อมูล Profile
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    // TODO: เรียกใช้ API PUT หรือ POST นำข้อมูลไปบันทึก
    // final body = {
    //   'firstName': _firstNameCtrl.text,
    //   'lastName': _lastNameCtrl.text,
    //   'address1': _address1Ctrl.text,
    //   'address2': _address2Ctrl.text,
    // };

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
      _isEdited = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEdited)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    // Email Group
                    _buildLabel('Email'),
                    GestureDetector(
                      onTap: () async {
                        final newEmail = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EmailEditPage(currentEmail: _email),
                          ),
                        );
                        if (newEmail != null && newEmail is String) {
                          setState(() {
                            _email = newEmail;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _email,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Group
                    _buildLabel('Name'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildTextField(_firstNameCtrl),
                          const Divider(height: 1, color: Colors.grey),
                          _buildTextField(_lastNameCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Address Group
                    _buildLabel('Address'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildTextField(_address1Ctrl),
                          const Divider(height: 1, color: Colors.grey),
                          _buildTextField(_address2Ctrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }
}
