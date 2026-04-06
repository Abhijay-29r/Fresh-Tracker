import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class DatabaseService {
  // The name of the "box" (table) where we store our groceries
  static const String _boxName = 'pantryBox';

  // 1. Initialize the database and register our custom adapter
  static Future<void> init() async {
    // We register the adapter we just generated in the last step
    Hive.registerAdapter(FoodItemAdapter());
    // Open the box so it's ready to be read/written to
    await Hive.openBox<FoodItem>(_boxName);
  }

  // 2. Get all saved items
  static List<FoodItem> getItems() {
    final box = Hive.box<FoodItem>(_boxName);
    final items = box.values.toList();

    // Sort items so the ones expiring soonest are at the top
    items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return items;
  }

  // 3. Add a new item to the database
  static Future<void> addItem(FoodItem item) async {
    final box = Hive.box<FoodItem>(_boxName);
    await box.add(item); // Hive automatically assigns it a unique key
  }

  // 4. Delete an item (e.g., when the user eats it or throws it away)
  static Future<void> deleteItem(FoodItem item) async {
    await item
        .delete(); // Because our model extends HiveObject, it can delete itself!
  }
}
