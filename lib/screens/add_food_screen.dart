
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
  final TextEditingController _kcalPer100gController = TextEditingController();
  String? _selectedGroup;

  double _calculatedKcal = 0.0;

  final List<String> _groups = [
    'Meat',
    'Milk',
    'Fruits & Veggies',
    'Bread & Cereal',
  ];

  void _calculateCalories() {
    final grams = double.tryParse(_gramsController.text) ?? 0;
    final kcalPer100g = double.tryParse(_kcalPer100gController.text) ?? 0;
    setState(() {
      _calculatedKcal = grams / 100 * kcalPer100g;
    });
  }

  Future<void> _addFoodLocally() async {
    if (_nameController.text.isEmpty || _selectedGroup == null) return;

    final foodItem = {
      'name': _nameController.text.trim(),
      'grams': double.tryParse(_gramsController.text) ?? 0,
      'kcalPer100g': double.tryParse(_kcalPer100gController.text) ?? 0,
      'totalKcal': _calculatedKcal,
      'group': _selectedGroup,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList('foods') ?? [];
    currentList.add(jsonEncode(foodItem));
    await prefs.setStringList('foods', currentList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aliment salvat local!')),
    );

    _nameController.clear();
    _gramsController.clear();
    _kcalPer100gController.clear();
    setState(() {
      _selectedGroup = null;
      _calculatedKcal = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaugă aliment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nume aliment'),
            ),
            TextField(
              controller: _gramsController,
              decoration: const InputDecoration(labelText: 'Grame'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateCalories(),
            ),
            TextField(
              controller: _kcalPer100gController,
              decoration: const InputDecoration(labelText: 'Kcal per 100g'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateCalories(),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              items: _groups
                  .map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Grupa alimentară'),
            ),
            const SizedBox(height: 16),
            Text('Total kcal: ${_calculatedKcal.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addFoodLocally,
              child: const Text('Adaugă'),
            ),
          ],
        ),
      ),
    );
  }
}
