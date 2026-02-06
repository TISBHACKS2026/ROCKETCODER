import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/services/supabase_service.dart';

class LostFoundDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const LostFoundDetailsScreen({super.key, required this.item});

  @override
  State<LostFoundDetailsScreen> createState() => _LostFoundDetailsScreenState();
}

class _LostFoundDetailsScreenState extends State<LostFoundDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bool isMyReport = widget.item['reporter_email'] == _supabaseService.currentUser?.email;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item['type'] == 'lost' ? 'Lost Item Details' : 'Found Item Details',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item['image_url'] != null)
              Image.network(
                widget.item['image_url'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: AppColors.background,
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item['title'] ?? 'Unnamed Item',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.item['type'] == 'lost' ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item['type']?.toUpperCase() ?? '',
                          style: TextStyle(
                            color: widget.item['type'] == 'lost' ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.item['location'] ?? 'Location unknown',
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () async {
                        if (isMyReport) {
                          await _handleResolve();
                        } else {
                          await _handleContact();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMyReport ? Colors.orange : AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                        isMyReport
                            ? 'MARK AS RESOLVED'
                            : (widget.item['type'] == 'found' ? 'MESSAGE FINDER' : 'MESSAGE OWNER'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResolve() async {
    setState(() => _isProcessing = true);
    try {
      await _supabaseService.completeLostFoundRecovery(
        itemId: widget.item['id'],
        reporterEmail: widget.item['reporter_email'],
        ownerEmail: _supabaseService.currentUser?.email ?? '', 
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked as resolved! Points awarded.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleContact() async {
    setState(() => _isProcessing = true);
    try {
      final String convId = await _supabaseService.getOrCreateConversation(
          widget.item['id'],
          widget.item['reporter_email']
      );

      if (mounted) {
        Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'conversation_id': convId,
              'seller': widget.item['reporter_email'],
              'title': widget.item['title'],
              'item_id': widget.item['id'],
              'category': widget.item['category'] ?? 'OTHER',
              'is_lost_found': true,
            }
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}