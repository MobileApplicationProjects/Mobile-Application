import 'package:flutter/material.dart';
import '../admin/admin_add_reward_page.dart';
import '../services/reward_service.dart';

class RewardsPage extends StatefulWidget {
  final bool isAdmin;
  final int currentBalance;
  const RewardsPage({super.key, this.isAdmin = false, this.currentBalance = 0});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final RewardService _rewardService = RewardService();
  List<Map<String, dynamic>> _rewards = [];
  bool _isLoading = true;
  String? _error;
  int _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.currentBalance;
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _rewardService.getRewards();
      if (mounted) {
        setState(() {
          _rewards = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatExpiry(dynamic expiryDate) {
    if (expiryDate == null) return 'ไม่มีวันหมดอายุ';
    try {
      final dt = DateTime.parse('$expiryDate');
      return 'ถึง ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '$expiryDate';
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
          'Rewards',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                backgroundColor: Colors.red[700],
                label: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Top Card (Medal & Token)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image.asset(
                      'assets/images/medal.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.workspace_premium,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_currentBalance',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // "Go to challenge" Button
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videogame_asset, color: Colors.black),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Go to challenge to get more token',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.black),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== REWARDS LIST FROM API =====
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.grey[500],
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'โหลดข้อมูลไม่สำเร็จ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadRewards,
                          icon: const Icon(Icons.refresh),
                          label: const Text('ลองใหม่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_rewards.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'ยังไม่มีของรางวัลในขณะนี้',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                )
              else
                ...List.generate(_rewards.length, (index) {
                  final r = _rewards[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRewardItemFromApi(r),
                  );
                }),

              const SizedBox(height: 24),

              // ========== ADMIN ONLY: Add Reward Button ==========
              if (widget.isAdmin) ...[
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAddRewardPage(),
                      ),
                    );
                    // Refresh the list if admin added a new reward
                    if (result == true) {
                      _loadRewards();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[800]!, Colors.red[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'เพิ่มของรางวัลใหม่',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItemFromApi(Map<String, dynamic> reward) {
    final String title = reward['title'] ?? '';
    final String partnerName = reward['partner_name'] ?? '';
    final String description = reward['description'] ?? '';
    final String? imageUrl = reward['image_url'];
    final int costInTokens = reward['cost_in_tokens'] ?? 0;
    final bool isDonation =
        reward['is_donation'] == 1 || reward['is_donation'] == true;
    final String expiryStr = _formatExpiry(reward['expiry_date']);

    return GestureDetector(
      onTap: () => _showRewardDetails(reward),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Logo / Image ---
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 1),
                color: Colors.grey[100],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        isDonation
                            ? Icons.volunteer_activism
                            : Icons.card_giftcard,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    )
                  : Icon(
                      isDonation
                          ? Icons.volunteer_activism
                          : Icons.card_giftcard,
                      size: 30,
                      color: Colors.grey[500],
                    ),
            ),

            const SizedBox(width: 16),

            // --- Text Content ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerName.isNotEmpty ? partnerName : title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expiryStr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDonation ? 'ไม่จำกัดจำนวน' : '$costInTokens',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'HOME',
              isActive: true,
            ),
            _buildNavItem(
              icon: Icons.location_on_rounded,
              label: 'MAP',
              isActive: false,
            ),
            _buildNavItem(
              icon: Icons.track_changes_rounded,
              label: 'CHALLENGE',
              isActive: false,
            ),
            _buildNavItem(
              icon: Icons.ios_share_rounded,
              label: 'SHARE',
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? Colors.red[700]! : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _showRewardDetails(Map<String, dynamic> reward) {
    final String title = reward['title'] ?? '';
    final String partnerName = reward['partner_name'] ?? '';
    final String description =
        reward['description'] ?? 'ไม่มีคำอธิบายเพิ่มเติม';
    final int costInTokens = reward['cost_in_tokens'] ?? 0;
    final int rewardId = reward['id'] ?? 0;
    final String? imageUrl = reward['image_url'];
    final bool isDonation =
        reward['is_donation'] == 1 || reward['is_donation'] == true;
    final String expiryStr = _formatExpiry(reward['expiry_date']);

    final bool canRedeem = _currentBalance >= costInTokens;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // use StatefulBuilder if we want internal state, but since we just do an action it's fine
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF1D1D1D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          isDonation
                                              ? Icons.volunteer_activism
                                              : Icons.card_giftcard,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                  )
                                : Icon(
                                    isDonation
                                        ? Icons.volunteer_activism
                                        : Icons.card_giftcard,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        Text(
                          partnerName.isNotEmpty ? partnerName : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (partnerName.isNotEmpty && title != partnerName) ...[
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Requirements
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[800],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isDonation
                                        ? 'ไม่จำกัดจำนวน'
                                        : '$costInTokens Token',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    expiryStr,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Description
                        const Text(
                          'รายละเอียด',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Bottom Button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D1D),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: canRedeem
                        ? () async {
                            Navigator.pop(ctx); // Close details modal
                            _processRedemption(rewardId, costInTokens);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRedeem
                          ? Colors.red[700]
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[800],
                      disabledForegroundColor: Colors.grey[500],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: canRedeem ? 4 : 0,
                    ),
                    child: Text(
                      canRedeem ? 'แลกของรางวัลเลย' : 'Token ไม่เพียงพอ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _processRedemption(int rewardId, int costInTokens) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      await _rewardService.redeemReward(rewardId);
      if (mounted) {
        Navigator.pop(context); // close progress

        setState(() {
          _currentBalance -= costInTokens;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ แลกของรางวัลสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRewards(); // refresh rewards for stock changes
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ไม่สามารถแลกได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRewards();
      }
    }
  }
}
