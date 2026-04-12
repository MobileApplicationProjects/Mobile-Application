import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/challenge_service.dart';

class AdminAddChallengePage extends StatefulWidget {
  final Map<String, dynamic>? challenge;
  const AdminAddChallengePage({super.key, this.challenge});

  @override
  State<AdminAddChallengePage> createState() => _AdminAddChallengePageState();
}

class _AdminAddChallengePageState extends State<AdminAddChallengePage> {
  final _formKey = GlobalKey<FormState>();
  final ChallengeService _challengeService = ChallengeService();

  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _targetValueCtrl;
  late TextEditingController _rewardCtrl;
  late TextEditingController _deadlineCtrl;

  String _targetType = 'Steps';
  bool _noLimitDeadline = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _titleCtrl = TextEditingController(text: c?['title'] ?? '');
    _descriptionCtrl = TextEditingController(text: c?['description'] ?? '');
    _targetValueCtrl = TextEditingController(text: c?['target_value']?.toString() ?? '');
    _rewardCtrl = TextEditingController(text: c?['reward_amount']?.toString() ?? '');
    
    _targetType = c?['target_type'] ?? 'Steps';

    if (c?['deadline'] != null && c?['deadline'] != 'No limit date') {
      try {
        final dt = DateTime.parse(c!['deadline']);
        _deadlineCtrl = TextEditingController(text: DateFormat('dd/MM/yyyy HH:mm:ss').format(dt));
        _noLimitDeadline = false;
      } catch (_) {
        _deadlineCtrl = TextEditingController(text: c!['deadline'].toString());
        _noLimitDeadline = false;
      }
    } else {
      _deadlineCtrl = TextEditingController();
      _noLimitDeadline = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _targetValueCtrl.dispose();
    _rewardCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.red[700]!,
              onPrimary: Colors.white,
              surface: const Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _deadlineCtrl.text = DateFormat('dd/MM/yyyy HH:mm:ss').format(fullDateTime);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final challengeData = {
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'target_type': _targetType,
        'target_value': int.tryParse(_targetValueCtrl.text.trim()) ?? 0,
        'reward_amount': int.parse(_rewardCtrl.text.trim()),
        'deadline': _noLimitDeadline ? null : _deadlineCtrl.text.trim(),
      };

      if (widget.challenge != null) {
        // Edit mode
        await _challengeService.updateChallenge(widget.challenge!['id'], challengeData);
      } else {
        // Create mode
        await _challengeService.createChallenge(challengeData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.challenge != null ? '✅ อัปเดต Challenge สำเร็จ!' : '✅ เพิ่ม Challenge สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.challenge != null ? 'Admin: แก้ไข Challenge' : 'Admin: เพิ่ม Challenge',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAdminBadge(),
                const SizedBox(height: 24),
                _buildSectionLabel('รายละเอียดส่วนหัว'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleCtrl,
                  label: 'หัวข้อ Challenge',
                  hint: 'เช่น Morning Walk',
                  icon: Icons.track_changes_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณาใส่หัวข้อ' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionCtrl,
                  label: 'คำอธิบาย',
                  hint: 'เช่น เดินให้ครบ 2,000 ก้าว...',
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('เงื่อนไขความสำเร็จ (Target)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _targetType,
                            dropdownColor: const Color(0xFF2A2A2A),
                            style: const TextStyle(color: Colors.white),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: ['Steps', 'Distance', 'Time'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _targetType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _buildTextField(
                        controller: _targetValueCtrl,
                        label: 'เป้าหมาย (Value)',
                        hint: '2000',
                        icon: Icons.flag_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'ระบุเป้าหมาย' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('รางวัล'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _rewardCtrl,
                  label: 'รางวัล (Token)',
                  hint: '50',
                  icon: Icons.monetization_on_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'กรุณาใส่รางวัล';
                    if (int.tryParse(v) == null) return 'ตัวเลขเท่านั้น';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('กำหนดระยะเวลา'),
                const SizedBox(height: 8),
                
                // No Limit Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.all_inclusive, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ไม่มีวันหมดอายุ (No limit date)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _noLimitDeadline,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) => setState(() => _noLimitDeadline = val),
                      ),
                    ],
                  ),
                ),
                
                if (!_noLimitDeadline) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDate,
                    child: IgnorePointer(
                      child: _buildTextField(
                        controller: _deadlineCtrl,
                        label: 'วันและหมดอายุ',
                        hint: 'แตะเพื่อเลือกวันที่/เวลา',
                        icon: Icons.calendar_month_rounded,
                        validator: (v) => (!_noLimitDeadline && (v == null || v.isEmpty)) ? 'กรุณาเลือกวันหมดอายุ' : null,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.challenge != null ? 'บันทึกการแก้ไข' : 'เพิ่ม Challenge',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[700]!),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.red[300], size: 18),
          const SizedBox(width: 8),
          Text(
            'Admin Mode — ผู้จัดการ Challenge',
            style: TextStyle(color: Colors.red[300], fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
