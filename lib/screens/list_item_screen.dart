import 'package:flutter/material.dart';
import 'package:eco_tisb/utils/colors.dart';
import 'package:eco_tisb/utils/constants.dart';
import 'package:eco_tisb/widgets/custom_button.dart';
import 'package:eco_tisb/services/supabase_service.dart';
import 'package:eco_tisb/models/item.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ListItemScreen extends StatefulWidget {
  const ListItemScreen({super.key});

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String? _selectedGrade;
  String _selectedCondition = 'Like New';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  int _getConditionRating(String condition) {
    switch (condition) {
      case 'New': return 5;
      case 'Like New': return 4;
      case 'Used': return 3;
      case 'Fair': return 2;
      case 'Poor': return 1;
      default: return 3;
    }
  }
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _postItem() async {
    if (_titleController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? uploadedUrl; 

      if (_selectedImage != null) {
        uploadedUrl = await _supabaseService.uploadItemImage(_selectedImage!);
      }

      final newItem = Item(
        id: '',
        sellerEmail: _supabaseService.currentUser!.email!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Grade: $_selectedGrade'
            : 'Grade: $_selectedGrade | ${_descriptionController.text.trim()}',
        category: _selectedCategory,
        conditionRating: _getConditionRating(_selectedCondition),
        imageUrl: uploadedUrl ?? 'https://via.placeholder.com/150',
        isSwapped: false,
        createdAt: DateTime.now(),
      );

      await _supabaseService.createItem(newItem);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Listing',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photos (Max 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildPhotoUploadRow(),
                const SizedBox(height: 16),
                _buildEcoBanner(),
                const SizedBox(height: 24),
                _buildTextField('Item Title', _titleController, 'e.g., IB Math HL Textbook'),
                const SizedBox(height: 20),
                _buildTextField('Description', _descriptionController, 'e.g., Slightly worn edges, no markings inside', maxLines: 3),
                const SizedBox(height: 20),
                _buildCategoryGradeRow(),
                const SizedBox(height: 20),
                const Text('Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildConditionPicker(),
                const SizedBox(height: 32),
                CustomButton(
                  text: _isLoading ? 'Posting...' : 'Post Giveaway',
                  icon: _isLoading ? null : Icons.arrow_forward,
                  onPressed: _isLoading ? () {} : _postItem,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        ],
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGradeRow() {
    return Row(
      children: [
        Expanded(child: _buildDropdown('Category', _selectedCategory, AppConstants.categories, (v) => setState(() => _selectedCategory = v))),
        const SizedBox(width: 12),
        Expanded(child: _buildDropdown('Grade Level', _selectedGrade, AppConstants.gradeLevels, (v) => setState(() => _selectedGrade = v))),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
          child: DropdownButton<String>(
            value: value,
            hint: const Text('Select'),
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppConstants.conditions.map((condition) {
          final isSelected = _selectedCondition == condition;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCondition = condition),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppColors.primaryGreen : AppColors.divider, width: isSelected ? 2 : 1),
                ),
                child: Text(condition, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoUploadRow() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen, width: 2),
          color: AppColors.primaryGreen.withValues(alpha: 0.05),
        ),
        child: _selectedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: AppColors.primaryGreen, size: 32),
            Text('Add Photo', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3))),
      child: const Row(
        children: [
          Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text('Earn 50 Eco-Points! Helping reduce waste at TISB.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}