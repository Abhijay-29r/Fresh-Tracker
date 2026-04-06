import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models.dart';
import 'database_service.dart';
import 'notification_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _unitController =
      TextEditingController(text: 'pcs');

  DateTime? _selectedDate;
  bool _isLoading = false;
  String _selectedCategory = 'Pantry';
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // --- THE MAGIC BARCODE SCANNER (Using simple_barcode_scanner) ---
  Future<void> _scanBarcode() async {
    String? barcode;

    // 1. Open a dialog with the camera view
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              barcode = barcodes.first.rawValue;
              Navigator.pop(context); // Close scanner when code found
            }
          },
        ),
      ),
    );

    // 2. If we got a barcode, fetch from API (This part stays the same!)
    if (barcode != null && barcode!.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final url = Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
        final response = await http.get(url);
        final data = json.decode(response.body);

        if (data['status'] == 1) {
          final product = data['product'];
          setState(() {
            _nameController.text = product['product_name'] ?? 'Unknown Product';
            _imageUrl = product['image_front_url'];
          });
          _showSnackBar('Product found!');
        } else {
          _showSnackBar('Product not found.');
        }
      } catch (e) {
        _showSnackBar('Network error.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty || _selectedDate == null) {
      _showSnackBar('Please enter a name and select a date.');
      return;
    }

    final newItem = FoodItem(
      name: _nameController.text.trim(),
      expiryDate: _selectedDate!,
      category: _selectedCategory,
      imageUrl: _imageUrl,
      quantity: double.tryParse(_quantityController.text) ?? 1.0,
      unit: _unitController.text.trim().isEmpty
          ? 'pcs'
          : _unitController.text.trim(),
    );

    await DatabaseService.addItem(newItem);

    await NotificationService.scheduleExpiryWarning(
      id: newItem.key.hashCode,
      itemName: newItem.name,
      expiryDate: newItem.expiryDate,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // If the scanner found an image, show it!
                if (_imageUrl != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_imageUrl!,
                          height: 120, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Name TextField with Scanner Button
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.fastfood),
                    // THE SCANNER BUTTON
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Colors.blue, size: 30),
                      onPressed: _scanBarcode,
                      tooltip: 'Scan Barcode',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quantity and Unit Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (e.g., kg, ml, pcs)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                  items: ['Pantry', 'Fridge', 'Freezer'].map((String category) {
                    return DropdownMenuItem(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedCategory = newValue!),
                ),
                const SizedBox(height: 20),

                // Date Picker
                OutlinedButton.icon(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_selectedDate == null
                      ? 'Select Expiry Date'
                      : 'Expires: ${DateFormat.yMMMd().format(_selectedDate!)}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save to Pantry',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),

          // Show a loading spinner while fetching the API
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}
