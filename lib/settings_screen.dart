import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  void _loadPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final price = prefs.getDouble('price') ?? 0.09;
    _priceController.text = price.toString();
  }

  void _savePrice() async {
    final prefs = await SharedPreferences.getInstance();
    final price = double.tryParse(_priceController.text) ?? 0.09;
    await prefs.setDouble('price', price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: '单价(元)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                ElevatedButton(onPressed: _savePrice, child: Text('保存')),
              ],
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Export data functionality to be implemented
              },
              child: Text('导出数据'),
            ),
          ],
        ),
      ),
    );
  }
}
