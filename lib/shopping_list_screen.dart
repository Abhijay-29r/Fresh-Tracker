import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // REQUIRED for deep linking

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  late Box _shoppingBox;

  @override
  void initState() {
    super.initState();
    _shoppingBox = Hive.box('shoppingBox');
  }

  void _addItem() {
    if (_itemController.text.trim().isNotEmpty) {
      _shoppingBox.put(_itemController.text.trim(), false);
      _itemController.clear();
    }
  }

  // --- THE QUICK COMMERCE HACK ---
  Future<void> _launchStore(String store, String itemName) async {
    // 1. Clean up the text for a URL (e.g., "Whole Milk" becomes "Whole%20Milk")
    final query = Uri.encodeComponent(itemName);
    String urlString = '';

    // 2. Build the specific search URL based on the store
    if (store == 'blinkit') urlString = 'https://blinkit.com/s/?q=$query';
    if (store == 'amazon') urlString = 'https://www.amazon.in/s?k=$query';
    if (store == 'zepto')
      urlString = 'https://www.zeptonow.com/search?q=$query';

    final url = Uri.parse(urlString);

    // 3. Launch the browser or the installed app
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the store')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Item Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Add groceries...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _addItem,
                  mini: true,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          // The List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _shoppingBox.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return const Center(
                    child: Text("You're all stocked up!",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final key = box.keyAt(index);
                    final isChecked = box.getAt(index) as bool;

                    return Dismissible(
                      key: Key(key.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        box.delete(key);
                      },
                      child: ListTile(
                        // 1. The Checkbox
                        leading: Checkbox(
                          value: isChecked,
                          activeColor: Colors.green,
                          onChanged: (bool? value) => box.put(key, value!),
                        ),
                        // 2. The Text
                        title: Text(
                          key.toString(),
                          style: TextStyle(
                            decoration:
                                isChecked ? TextDecoration.lineThrough : null,
                            color: isChecked ? Colors.grey : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // 3. The Store Search Menu!
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.green),
                          tooltip: 'Search online stores',
                          onSelected: (store) =>
                              _launchStore(store, key.toString()),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'blinkit',
                              child: Text('Search on Blinkit ⚡'),
                            ),
                            const PopupMenuItem(
                              value: 'zepto',
                              child: Text('Search on Zepto 🟣'),
                            ),
                            const PopupMenuItem(
                              value: 'amazon',
                              child: Text('Search on Amazon 📦'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
