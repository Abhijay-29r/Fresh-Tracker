import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'database_service.dart';
import 'add_item_screen.dart';
import 'notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Credits
  void _showCredits(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FreshTrack',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.eco, color: Colors.green, size: 50),
      applicationLegalese: '© 2026 Abhijay Junnare. All rights reserved.',
      children: [
        const SizedBox(height: 20),
        const Text(
          "Developed by Abhijay Junnare",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text("Computer Engineering Department"),
        const Text("KKWIEER, Nashik"),
        const SizedBox(height: 15),
        const Text(
          "This project is released under the MIT License. "
          "Unauthorized redistribution without attribution is prohibited.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _searchQuery = "";

  Color _getExpiryColor(int daysLeft) {
    if (daysLeft < 0) return Colors.grey;
    if (daysLeft <= 3) return Colors.red;
    if (daysLeft <= 7) return Colors.orange;
    return Colors.green;
  }

  Widget _buildPlaceholder(Color color, int daysLeft) {
    return CircleAvatar(
      backgroundColor: color.withAlpha(50),
      child: Icon(
        daysLeft < 0 ? Icons.delete_forever : Icons.inventory_2,
        color: color,
      ),
    );
  }

  // FEATURE 1: The Core Loop (Moving item to Shopping List)
  Future<void> _askToAddToShoppingList(String itemName) async {
    bool? addToList = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Need More?"),
        content: Text("Add '$itemName' to your shopping list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("NO, THANKS", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("YES, ADD IT",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (addToList == true) {
      final shoppingBox = Hive.box('shoppingBox');
      shoppingBox.put(itemName, false); // Add as unchecked
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$itemName added to Shopping List!")),
        );
      }
    }
  }

  // FEATURE 2: Quick Edit Quantity Dialog
  Future<void> _editQuantityDialog(FoodItem item) async {
    final TextEditingController qtyController =
        TextEditingController(text: item.quantity.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update ${item.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount Remaining (${item.unit})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              double newQty =
                  double.tryParse(qtyController.text) ?? item.quantity;
              Navigator.pop(context); // Close dialog

              if (newQty <= 0) {
                // If they changed it to 0, mark as eaten and ask to shop!
                item.status = 'eaten';
                await item.save();
                await NotificationService.cancelNotification(item.key.hashCode);
                await _askToAddToShoppingList(item.name);
              } else {
                // Otherwise, just save the new quantity
                item.quantity = newQty;
                await item.save();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "${item.name} quantity updated to $newQty ${item.unit}")),
                  );
                }
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // --- ADD THESE LINES BELOW ---
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCredits(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<FoodItem>>(
        valueListenable: Hive.box<FoodItem>('pantryBox').listenable(),
        builder: (context, box, _) {
          final allItems = DatabaseService.getItems();

          final items = allItems.where((item) {
            return item.status == 'active' &&
                item.name.toLowerCase().contains(_searchQuery);
          }).toList();

          if (items.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'Your pantry is empty!'
                    : 'No items match "$_searchQuery"',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final daysLeft =
                  item.expiryDate.difference(DateTime.now()).inDays;
              final statusColor = _getExpiryColor(daysLeft);

              return Dismissible(
                key: Key(item.key.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.blueGrey,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.help_outline,
                      color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  // 1. Ask if Eaten or Wasted
                  bool? eaten = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Finish Item?"),
                      content: Text("Did you finish the ${item.name}?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("WASTED",
                              style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("EATEN"),
                        ),
                      ],
                    ),
                  );

                  if (eaten == null) return false;

                  // 2. Save status
                  item.status = eaten ? 'eaten' : 'wasted';
                  await item.save();
                  await NotificationService.cancelNotification(
                      item.key.hashCode);

                  // 3. Ask to add to shopping list
                  await _askToAddToShoppingList(item.name);

                  return true;
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    // TAPPING THE CARD OPENS THE QUANTITY EDITOR
                    onTap: () => _editQuantityDialog(item),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) =>
                                      _buildPlaceholder(statusColor, daysLeft),
                                )
                              : _buildPlaceholder(statusColor, daysLeft),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    // UPDATED SUBTITLE: Shows Quantity and Unit now!
                    subtitle: Row(
                      children: [
                        Icon(
                          item.category == 'Fridge'
                              ? Icons.kitchen
                              : Icons.shelves,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.quantity} ${item.unit} • ${DateFormat.yMMMd().format(item.expiryDate)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      daysLeft < 0 ? 'Expired' : '$daysLeft d',
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
