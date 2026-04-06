import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Impact',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // ValueListenableBuilder makes the chart update live if you swipe an item!
      body: ValueListenableBuilder<Box<FoodItem>>(
        valueListenable: Hive.box<FoodItem>('pantryBox').listenable(),
        builder: (context, box, _) {
          // 1. Gather the Data
          final items = box.values.toList();
          final int eatenCount = items.where((i) => i.status == 'eaten').length;
          final int wastedCount =
              items.where((i) => i.status == 'wasted').length;
          final int activeCount =
              items.where((i) => i.status == 'active').length;

          final int totalResolved = eatenCount + wastedCount;

          // 2. Calculate Pantry Efficiency
          final double efficiency =
              totalResolved == 0 ? 0.0 : (eatenCount / totalResolved);

          final int efficiencyPercentage = (efficiency * 100).round();

          // 3. Determine the color based on how well the user is doing
          Color getScoreColor(int percent) {
            if (totalResolved == 0) return Colors.grey;
            if (percent >= 80) return Colors.green;
            if (percent >= 50) return Colors.orange;
            return Colors.red;
          }

          final scoreColor = getScoreColor(efficiencyPercentage);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- TOP DASHBOARD: The Chart ---
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      children: [
                        const Text(
                          "Pantry Efficiency",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // The visual ring
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: totalResolved == 0 ? 1.0 : efficiency,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.withAlpha(50),
                                color: totalResolved == 0
                                    ? Colors.grey
                                    : scoreColor,
                              ),
                            ),
                            // The percentage text in the middle
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  totalResolved == 0
                                      ? '--%'
                                      : '$efficiencyPercentage%',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: totalResolved == 0
                                        ? Colors.grey
                                        : scoreColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          totalResolved == 0
                              ? "Finish some items to see your score!"
                              : (efficiencyPercentage >= 80
                                  ? "Great job reducing waste!"
                                  : "Room for improvement!"),
                          style: const TextStyle(
                              fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- BOTTOM DASHBOARD: The Raw Numbers ---
                const Text(
                  "All-Time Stats",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Currently Tracking", "$activeCount",
                          Colors.blue, Icons.inventory_2),
                      _buildStatCard("Total Finished", "$eatenCount",
                          Colors.green, Icons.restaurant),
                      _buildStatCard("Total Wasted", "$wastedCount", Colors.red,
                          Icons.delete_outline),
                      _buildStatCard("Total Logged", "${items.length}",
                          Colors.purple, Icons.assessment),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to make the little stat boxes look nice
  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
