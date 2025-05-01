
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_food_screen.dart';
import 'food_history_screen.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  late SharedPreferences prefs;
  double weight = 190.0;
  double baseCalories = 2350.0;
  bool isMonday = DateTime.now().weekday == DateTime.monday;

  late Map<String, double> groupTargets;
  late Map<String, double> groupTotals;

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    weight = prefs.getDouble('currentWeight') ?? 190.0;
    updateGroupTargets();
    await loadData();
  }

  void updateGroupTargets() {
    final deltaWeight = weight - 190;
    final int k = (deltaWeight / 5).round();
    final adjustedCalories = 2350 + (-75 * k);

    baseCalories = adjustedCalories.toDouble();

    final scalingFactor = baseCalories / 1600;
    groupTargets = {
      'Meat': (300 * scalingFactor),
      'Milk': (350 * scalingFactor),
      'Fruits & Veggies': (600 * scalingFactor),
      'Bread & Cereal': (350 * scalingFactor),
    };

    groupTotals = {
      'Meat': 0,
      'Milk': 0,
      'Fruits & Veggies': 0,
      'Bread & Cereal': 0,
    };
  }

  Future<void> loadData() async {
    final List<String> storedFoods = prefs.getStringList('foods') ?? [];
    final today = DateTime.now();

    final filteredFoods = storedFoods.map((e) => jsonDecode(e)).where((item) {
      final timestamp = DateTime.tryParse(item['timestamp'] ?? '');
      return timestamp != null &&
          timestamp.year == today.year &&
          timestamp.month == today.month &&
          timestamp.day == today.day;
    });

    groupTotals.updateAll((key, value) => 0); // reset totals

    for (var item in filteredFoods) {
      final group = item['group'];
      final kcal = item['totalKcal'] ?? 0;
      final isIceCream = (item['name'] as String).toLowerCase().contains('ice cream');
      if (isMonday && isIceCream) continue;

      if (groupTotals.containsKey(group)) {
        groupTotals[group] = groupTotals[group]! + kcal;
      }
    }

    setState(() {});
  }

  void _showWeightDialog() {
    final controller = TextEditingController(text: weight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizează greutatea'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Greutate (lbs)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newWeight = double.tryParse(controller.text);
              if (newWeight != null) {
                prefs.setDouble('currentWeight', newWeight);
                setState(() {
                  weight = newWeight;
                  updateGroupTargets();
                  loadData();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = groupTotals.values.fold(0.0, (sum, val) => sum + val);
    return Scaffold(
      appBar: AppBar(title: const Text('Rezumat zilnic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isMonday)
              Column(
                children: [
                  const Text(
                    '🍦 Azi e ziua de înghețată – savurează în liniște!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showWeightDialog,
                    child: const Text('Setează greutatea'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            Text('Greutate curentă: ${weight.toStringAsFixed(1)} lbs'),
            const SizedBox(height: 10),
            Text('Target zilnic: ${baseCalories.toInt()} kcal'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: groupTargets.entries.map((entry) {
                  final group = entry.key;
                  final target = entry.value;
                  final actual = groupTotals[group]!;
                  final percent = (actual / target).clamp(0.0, 1.0).toDouble();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$group: ${actual.toStringAsFixed(1)} / ${target.toInt()} kcal'),
                      LinearProgressIndicator(value: percent),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            Text('Total consumat: ${total.toStringAsFixed(0)} kcal'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFoodScreen()),
                );
                loadData();
              },
              child: const Text('Adaugă aliment'),
            ),
            ElevatedButton(
                onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodHistoryScreen()),
                    );
                },
                child: const Text('Vezi istoric'),
                ),
          ],
        ),
      ),
    );
  }
}
