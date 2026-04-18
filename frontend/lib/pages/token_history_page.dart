import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class TokenHistoryItem {
  final String time;
  final String title;
  final String amount;

  TokenHistoryItem({
    required this.time,
    required this.title,
    required this.amount,
  });
}

class TokenHistoryPage extends StatefulWidget {
  const TokenHistoryPage({super.key});

  @override
  State<TokenHistoryPage> createState() => _TokenHistoryPageState();
}

class _TokenHistoryPageState extends State<TokenHistoryPage> {
  bool _isLoading = true;
  List<TokenHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await AuthService().fetchTransactions();
      
      final List<TokenHistoryItem> parsedHistory = transactions.map((t) {
        // Parse time
        final date = DateTime.tryParse(t['created_at'].toString())?.toLocal() ?? DateTime.now();
        final timeString = DateFormat('HH:mm').format(date);
        
        // Map transaction_type to readable title
        String rawType = t['transaction_type'] ?? 'Unknown';
        String title = rawType;
        if (rawType.toLowerCase() == 'earn_step') {
          title = 'Daily Step';
        } else if (rawType.toLowerCase() == 'earn_challenge') {
          title = 'Challenge Win';
        } else if (rawType.toLowerCase() == 'spend') {
          title = 'Redeemed Reward';
        }

        // Amount math
        final amountNum = t['amount'] is num ? t['amount'] as num : int.tryParse(t['amount'].toString()) ?? 0;
        final amountString = amountNum > 0 ? '+$amountNum' : '$amountNum';

        return TokenHistoryItem(
          time: timeString,
          title: title,
          amount: amountString,
        );
      }).toList();

      setState(() {
        _history = parsedHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Fetch token history error: $e');
      setState(() {
        _history = [];
        _isLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Token History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => _buildDivider(),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return _buildHistoryItem(
                        time: item.time,
                        title: item.title,
                        amount: item.amount,
                      );
                    },
                  ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHistoryItem({
    required String time,
    required String title,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTokenIcon(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[800],
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildTokenIcon() {
    return SizedBox(
      width: 32,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            child: _buildCoinDisk(),
          ),
          Positioned(
            top: 10,
            child: _buildCoinDisk(),
          ),
          Positioned(
            top: 0,
            child: _buildCoinDisk(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinDisk() {
    return Container(
      width: 26,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE047), // Yellow color for coin
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
            _buildNavItem(
              icon: Icons.location_on_rounded,
              label: 'MAP',
              isActive: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.track_changes_rounded,
              label: 'CHALLENGE',
              isActive: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.ios_share_rounded,
              label: 'SHARE',
              isActive: false,
              onTap: () {},
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
    required VoidCallback onTap,
  }) {
    final color = isActive ? Colors.red[700]! : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}
