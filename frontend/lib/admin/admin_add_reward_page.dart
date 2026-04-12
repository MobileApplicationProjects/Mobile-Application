import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/reward_service.dart';

class AdminAddRewardPage extends StatefulWidget {
  const AdminAddRewardPage({super.key});

  @override
  State<AdminAddRewardPage> createState() => _AdminAddRewardPageState();
}

class _AdminAddRewardPageState extends State<AdminAddRewardPage> {
  final _formKey = GlobalKey<FormState>();
  final RewardService _rewardService = RewardService();
  final ImagePicker _picker = ImagePicker();

  final _partnerNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _imageBytes; // for Image.memory preview (web + mobile)
  bool _isDonation = false;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _partnerNameCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกรูปได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'เลือกรูปจาก',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('คลังรูปภาพ', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('กล้อง', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _rewardService.uploadImage(_selectedImage!);
        setState(() => _isUploadingImage = false);
      }

      // Step 2: Create reward with image URL
      await _rewardService.createReward(
        partnerName: _partnerNameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        costInTokens: int.parse(_costCtrl.text.trim()),
        totalStock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        expiryDate: _expiryCtrl.text.trim().isEmpty ? null : _expiryCtrl.text.trim(),
        imageUrl: imageUrl,
        isDonation: _isDonation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ เพิ่มของรางวัลสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _isSubmitting = false;
      });
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
        title: const Text(
          'Admin: เพิ่มของรางวัล',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                // Admin Badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 24),
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
                        'Admin Mode — ผู้ใช้ทั่วไปจะมองไม่เห็นหน้านี้',
                        style: TextStyle(color: Colors.red[300], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // ===== IMAGE PICKER =====
                _buildSectionLabel('รูปโลโก้ / รูปของรางวัล'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showImageSourcePicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedImage != null ? Colors.red[600]! : Colors.grey[700]!,
                        width: 1.5,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedImage = null;
                                      _imageBytes = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('เปลี่ยนรูป', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: Colors.grey[500], size: 48),
                              const SizedBox(height: 10),
                              Text(
                                'แตะเพื่อเลือกรูป',
                                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'รองรับ JPEG, PNG, WebP (สูงสุด 5 MB)',
                                style: TextStyle(color: Colors.grey[700], fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('ข้อมูลร้านค้า / พาร์ทเนอร์'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _partnerNameCtrl,
                  label: 'ชื่อร้าน / พาร์ทเนอร์',
                  hint: 'เช่น Yoguruto Shop',
                  icon: Icons.store_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณาใส่ชื่อร้านค้า' : null,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('รายละเอียดของรางวัล'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleCtrl,
                  label: 'ชื่อของรางวัล',
                  hint: 'เช่น ส่วนลด 20 บาท',
                  icon: Icons.card_giftcard_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'กรุณาใส่ชื่อของรางวัล' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionCtrl,
                  label: 'คำอธิบาย',
                  hint: 'เช่น ใช้ 1,000 Token แลกส่วนลด 20 บาท...',
                  icon: Icons.description_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('ราคาและสต็อก'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _costCtrl,
                        label: 'ราคา (Token)',
                        hint: '1000',
                        icon: Icons.monetization_on_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณาใส่ราคา';
                          if (int.tryParse(v) == null) return 'ตัวเลขเท่านั้น';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _stockCtrl,
                        label: 'จำนวนสต็อก',
                        hint: '500',
                        icon: Icons.inventory_2_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _expiryCtrl,
                  label: 'วันหมดอายุ (dd/mm/yyyy)',
                  hint: '31/12/2026',
                  icon: Icons.calendar_month_rounded,
                ),

                const SizedBox(height: 20),
                // Donation toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volunteer_activism_rounded, color: Colors.green[400], size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'เป็นรายการบริจาค (Donation)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _isDonation,
                        activeColor: Colors.green[400],
                        onChanged: (val) => setState(() => _isDonation = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _isUploadingImage) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: (_isSubmitting || _isUploadingImage)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploadingImage ? 'กำลังอัพโหลดรูป...' : 'กำลังบันทึก...',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : const Text(
                            'เพิ่มของรางวัล',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
