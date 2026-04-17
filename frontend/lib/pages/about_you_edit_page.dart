import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AboutYouEditPage extends StatefulWidget {
  const AboutYouEditPage({super.key});

  @override
  State<AboutYouEditPage> createState() => _AboutYouEditPageState();
}

class _AboutYouEditPageState extends State<AboutYouEditPage> {
  bool _isLoading = true;
  bool _isEdited = false;

  DateTime? _birthDate;
  String _gender = 'Female';
  
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchAboutYouData();
    _heightCtrl.addListener(_onFieldChanged);
    _weightCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _heightCtrl.removeListener(_onFieldChanged);
    _weightCtrl.removeListener(_onFieldChanged);
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_isEdited && !_isLoading) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  // โหลดข้อมูล About you จาก API
  Future<void> _fetchAboutYouData() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.getProfile();
      final profile = result['profile'];

      setState(() {
        if (profile['birthDate'] != null) {
          _birthDate = DateTime.tryParse(profile['birthDate'].toString());
        } else {
          _birthDate = null;
        }
        
        // Map backend gender or fallback
        final String fetchedGender = profile['gender']?.toString() ?? 'Other';
        if (_genderOptions.contains(fetchedGender)) {
          _gender = fetchedGender;
        } else {
          _gender = 'Other';
        }

        _heightCtrl.text = '${profile['height'] ?? 0} cm';
        _weightCtrl.text = '${profile['weight'] ?? 0} kg';
        
        _isLoading = false;
        _isEdited = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // บันทึกข้อมูล About you ลง Database
  Future<void> _saveAboutYou() async {
    setState(() => _isLoading = true);

    try {
      final body = {
        'birthDate': _birthDate?.toIso8601String().split('T')[0],
        'gender': _gender,
        'height': double.tryParse(_heightCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        'weight': double.tryParse(_weightCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')),
      };
      
      await AuthService().updateProfile(body);

      setState(() {
        _isLoading = false;
        _isEdited = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('About you updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update About you: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
      _onFieldChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format date specifically for display (e.g., "12 Nov 1999")
    final dateString = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')} '
          '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_birthDate!.month - 1]} '
          '${_birthDate!.year}'
        : 'Select Date';

    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        title: const Text('About you Edit', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                onPressed: _isLoading ? null : _saveAboutYou,
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
                    // Birth date Group
                    _buildLabel('Birth date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateString,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gender Group
                    _buildLabel('Gender'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                          dropdownColor: Colors.white,
                          items: _genderOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _gender) {
                              setState(() {
                                _gender = newValue;
                              });
                              _onFieldChanged();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Physical Group
                    _buildLabel('Physical'),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          TextField(
                            controller: _heightCtrl,
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          TextField(
                            controller: _weightCtrl,
                            style: const TextStyle(color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
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
}
