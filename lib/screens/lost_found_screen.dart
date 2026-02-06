import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:eco_tisb/widgets/lost_found_card.dart';
import 'package:eco_tisb/screens/lost_found_details_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final String _selectedType = 'found';
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getLostFoundItems(_selectedType);
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lost & Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Text('Items found across TISB',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Text(
              "Found something? Report it here to help it find its way home.",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : RefreshIndicator(
              onRefresh: _fetchItems,
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return LostFoundCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostFoundDetailsScreen(item: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/report-item');
          if (result == true) {
            _fetchItems();
          }
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Report Found Item'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/marketplace');
          if (index == 1) Navigator.pushReplacementNamed(context, '/chat-list');
          if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Found'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No lost items currently listed.',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Text('Everything is where it should be!',
              style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}