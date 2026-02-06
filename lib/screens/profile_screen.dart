import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/widgets/circular_progress.dart';
import 'package:eco_tisb/widgets/stat_card.dart';
import 'package:eco_tisb/widgets/custom_button.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:eco_tisb/models/user_profile.dart';
import 'package:eco_tisb/models/item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  UserProfile? _profile;
  List<Item> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = _supabaseService.currentUser;
    if (user != null && user.email != null) {
      try {
        final profile = await _supabaseService.getUserProfile(user.email!);
        final listings = await _supabaseService.getUserListings(user.email!);

        if (mounted) {
          setState(() {
            _profile = profile;
            _listings = listings;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    final profileData = _profile ?? UserProfile(
      fullName: 'User',
      email: _supabaseService.currentUser?.email ?? 'Student',
      points: 0,
      co2Saved: 0.0,
      itemsRecycled: 0,
      treesSaved: 0.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchProfileData,
          color: AppColors.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildAvatarSection(profileData),
                const SizedBox(height: 32),
                _buildGreenScore(profileData),
                const SizedBox(height: 32),
                _buildEcoPointsCard(profileData),
                const SizedBox(height: 32),
                _buildImpactStats(profileData),
                const SizedBox(height: 32),
                _buildListingsSection(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              await _supabaseService.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserProfile profile) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 3),
              ),
              child: const Icon(Icons.person, size: 50, color: AppColors.textLight),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 16, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(profile.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(profile.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildGreenScore(UserProfile profile) {
    return Column(
      children: [
        const Text(
          'GREEN SCORE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CircularProgress(
          value: profile.points,
          maxValue: 2500,
          label: 'Points',
        ),
      ],
    );
  }

  Widget _buildEcoPointsCard(UserProfile profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.eco, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${profile.points} Eco-Points', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Keep trading to help the planet!', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStats(UserProfile profile) {
    final double treesSaved = profile.co2Saved / 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.park_rounded,
              value: treesSaved.toStringAsFixed(1),
              label: 'TREES',
              iconColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.autorenew_rounded,
              value: '${profile.itemsRecycled}',
              label: 'RECYCLED',
              iconColor: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.cloud_done_rounded,
              value: '${profile.co2Saved.toStringAsFixed(0)}kg',
              label: 'CO2',
              iconColor: const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('My Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        if (_listings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('You haven\'t listed any items yet.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ..._listings.map((item) => _buildListingTile(context, item)),

        Padding(
          padding: const EdgeInsets.all(24),
          child: CustomButton(
            text: 'List New Item',
            onPressed: () => Navigator.pushNamed(context, '/list-item').then((_) => _fetchProfileData()),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTile(BuildContext context, Item item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl ?? '',
              width: 50, height: 50, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], width: 50, height: 50, child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(item.isSwapped ? 'Status: Swapped' : 'Status: Active',
                    style: TextStyle(fontSize: 12, color: item.isSwapped ? AppColors.success : AppColors.primaryGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacementNamed(context, '/marketplace');
        if (index == 1) Navigator.pushReplacementNamed(context, '/chat-list');
        if (index == 3) Navigator.pushReplacementNamed(context, '/lost-found');
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Feed'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Lost & Found'),
      ],
    );
  }
}