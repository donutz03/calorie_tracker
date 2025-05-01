
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFoods = prefs.getStringList('foods') ?? [];

    Map<String, List<Map<String, dynamic>>> temp = {};

    for (var item in storedFoods.map((e) => jsonDecode(e))) {
      final timestamp = DateTime.tryParse(item['timestamp'] ?? '');
      if (timestamp == null) continue;

      final dateKey = "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

      temp.putIfAbsent(dateKey, () => []).add({
        'name': item['name'],
        'group': item['group'],
        'totalKcal': item['totalKcal'],
        'grams': item['grams'],
        'time': "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}"
      });
    }

    setState(() {
      groupedByDate = temp;
    });
  }

  Widget buildDayCard(String date, List<Map<String, dynamic>> foods) {
    final totalsByGroup = <String, double>{};
    double totalKcal = 0;

    for (var food in foods) {
      final group = food['group'];
      final kcal = food['totalKcal'] ?? 0.0;
      totalKcal += kcal;
      totalsByGroup[group] = (totalsByGroup[group] ?? 0) + kcal;
    }

    return ExpansionTile(
      title: Text('$date – ${totalKcal.toStringAsFixed(0)} kcal'),
      subtitle: Text(totalsByGroup.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)} kcal').join(', ')),
      children: foods.map((f) {
        return ListTile(
          title: Text('${f['name']} (${f['group']})'),
          subtitle: Text('${f['grams']}g • ${f['totalKcal'].toStringAsFixed(1)} kcal at ${f['time']}'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending

    return Scaffold(
      appBar: AppBar(title: const Text('Istoric alimente')),
      body: groupedByDate.isEmpty
          ? const Center(child: Text('Nicio intrare salvată.'))
          : ListView(
              children: sortedDates
                  .map((date) => buildDayCard(date, groupedByDate[date]!))
                  .toList(),
            ),
    );
  }
}
