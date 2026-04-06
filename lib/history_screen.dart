import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController handles the switching logic for us
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: 'Eaten'),
              Tab(icon: Icon(Icons.delete_outline), text: 'Wasted'),
            ],
          ),
        ),
        body: ValueListenableBuilder<Box<FoodItem>>(
          valueListenable: Hive.box<FoodItem>('pantryBox').listenable(),
          builder: (context, box, _) {
            final allItems = box.values.toList();

            return TabBarView(
              children: [
                // Tab 1: Eaten Items
                _buildHistoryList(
                  allItems.where((item) => item.status == 'eaten').toList(),
                  Colors.green,
                ),
                // Tab 2: Wasted Items
                _buildHistoryList(
                  allItems.where((item) => item.status == 'wasted').toList(),
                  Colors.red,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to build the list for each tab
  // Update this helper method in lib/history_screen.dart
  Widget _buildHistoryList(List<FoodItem> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No items found here.",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          Icon(Icons.fastfood, color: themeColor),
                    )
                  : Icon(Icons.fastfood, color: themeColor),
            ),
            title: Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text('Moved: ${DateFormat.yMMMd().format(item.expiryDate)}'),
            // NEW: Added a Row in trailing to show quantity AND a Restore button
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${item.quantity} ${item.unit}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.blue),
                  tooltip: 'Restore to Pantry',
                  onPressed: () async {
                    // Flip status back to active
                    item.status = 'active';
                    await item
                        .save(); // Hive magic: updates the database immediately

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${item.name} moved back to Pantry"),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
