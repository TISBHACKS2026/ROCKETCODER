import 'package:flutter/material.dart';
import 'package:eco_tisb/models/item.dart';
import 'package:eco_tisb/models/user_profile.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/widgets/custom_button.dart';
import 'package:eco_tisb/widgets/report_dialog.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  UserProfile? _sellerProfile;
  bool _isLoadingSeller = true;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    final profile = await _supabaseService.getUserProfile(widget.item.sellerEmail);
    if (mounted) {
      setState(() {
        _sellerProfile = profile;
        _isLoadingSeller = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.item.imageUrl ?? 'https://via.placeholder.com/400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildBadge(widget.item.conditionString, AppColors.primaryGreen),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBadge(widget.item.category ?? 'General', Colors.blueGrey),
                      const SizedBox(width: 8),
                      // Check for Grade info in description
                      if (widget.item.description?.contains('Grade:') ?? false)
                        _buildBadge(
                            widget.item.description!.split('Grade:')[1].split('|')[0].trim(),
                            Colors.orange
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildImpactCard(),
                  const SizedBox(height: 24),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description?.split('|').last.trim() ?? "No description provided.",
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text("Listed By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSellerInfo(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildImpactCard() {
    // Dynamically get impact from our service mapping
    final impactData = _supabaseService.categoryImpact[widget.item.category?.toUpperCase()] ??
        _supabaseService.categoryImpact['OTHER']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.primaryGreen, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Eco Impact", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                Text(
                  "By reusing this, you save approx. ${impactData['co2']}kg of CO2 and earn ${impactData['points']?.toInt()} points!",
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    if (_isLoadingSeller) return const LinearProgressIndicator();

    final String displayName = _sellerProfile?.fullName ?? "TISB User";
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: Text(initial, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text("${_sellerProfile?.points ?? 0} Eco-Points", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (widget.item.sellerEmail != _supabaseService.currentUser?.email)
            IconButton(
              icon: const Icon(Icons.flag, color: Colors.redAccent, size: 24),
              tooltip: 'Report User',
              onPressed: () => _showReportDialog(context),
            ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportedUserEmail: widget.item.sellerEmail,
        listingId: widget.item.id,
        onSubmit: (reason, details) => _supabaseService.reportUser(
          reportedUserEmail: widget.item.sellerEmail,
          reason: reason,
          details: details,
          listingId: widget.item.id,
        ),
      ),
    ).then((submitted) {
      if (submitted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. We will investigate.')),
        );
      }
    });
  }

  Widget _buildBottomAction() {
    final bool isMyItem = widget.item.sellerEmail == _supabaseService.currentUser?.email;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: CustomButton(
        text: isMyItem ? "MARK AS SWAPPED" : "I'M INTERESTED",
        onPressed: isMyItem ? () async {
          // Show a confirmation dialog
          bool? confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Swap"),
              content: const Text("Has this item been handed over? You will earn Eco-Points!"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Confirmed")),
              ],
            ),
          );

          if (confirm == true) {
            try {
              await _supabaseService.completeTransaction(
                itemId: widget.item.id,
                sellerEmail: widget.item.sellerEmail,
                buyerEmail: _supabaseService.currentUser?.email ?? '', // The current user is the buyer
                category: widget.item.category ?? 'OTHER',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Swapped! Points Awarded.")));
                Navigator.pop(context, true); // Pop back and trigger refresh
              }
            } catch (e) {
              debugPrint("Swap Error: $e");
            }
          }
        } : () async {
          try {
            final String convId = await _supabaseService.getOrCreateConversation(
                widget.item.id,
                widget.item.sellerEmail
            );

            if (context.mounted) {
              Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'conversation_id': convId,
                    'seller': widget.item.sellerEmail,
                    'title': widget.item.title,
                    'item_id': widget.item.id, // Fixed: use widget.item.id
                    'category': widget.item.category ?? 'OTHER', // Fixed: use widget.item.category
                    'is_lost_found': false, // Specifically for Marketplace
                  }
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting chat: $e')),
            );
          }
        },
      ),
    );
  }
}