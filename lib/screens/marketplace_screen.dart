import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/widgets/category_chip.dart';
import 'package:eco_tisb/widgets/item_card.dart';
import 'package:eco_tisb/models/item.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:eco_tisb/screens/item_details_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  int _currentIndex = 0;
  String _selectedCategory = 'All Items';
  final TextEditingController _searchController = TextEditingController();
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final items = await _supabaseService.getAvailableItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> get filteredItems {
    List<Item> results = _items;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      results = results.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final descriptionMatch = item.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || descriptionMatch;
      }).toList();
    }

    if (_selectedCategory != 'All Items') {
      results = results.where((item) {
        return item.category?.toUpperCase() == _selectedCategory.toUpperCase();
      }).toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/logo-nobg.png',
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TISB Market',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search textbooks, uniforms...',
                          hintStyle: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All Items'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Book'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Uniform'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Electronics'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : RefreshIndicator(
                onRefresh: _fetchItems,
                child: filteredItems.isEmpty
                    ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No items found matching your search')),
                  ],
                )
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final currentItem = filteredItems[index];
                    return ItemCard(
                      item: currentItem.toJson(),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailsScreen(item: currentItem),
                          ),
                        );
                        if (result == true) _fetchItems();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/list-item'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Sell Item', style: TextStyle(fontWeight: FontWeight.w600)),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/chat-list');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/lost-found');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Lost & Found',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return CategoryChip(
      label: label,
      isSelected: _selectedCategory == label,
      onTap: () => setState(() => _selectedCategory = label),
    );
  }
}