import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('单价已保存')));
  }

  Future<void> _exportData() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    final prefs = await SharedPreferences.getInstance();
    final allData = <String, dynamic>{};
    final keys = prefs.getKeys();

    for (var key in keys) {
      allData[key] = prefs.get(key);
    }

    final jsonString = jsonEncode(allData);
    final fileName = 'jinhuodata_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      final file = File('$directoryPath/$fileName');
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据已导出到: ${file.path}')));
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final allData = jsonDecode(jsonString) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      for (var key in allData.keys) {
        final value = allData[key];
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, value.cast<String>());
        }
      }
      _loadPrice();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据已成功导入')));
    }
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
              onPressed: _importData,
              child: Text('导入数据'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exportData,
              child: Text('导出数据'),
            ),
          ],
        ),
      ),
    );
  }
}
