
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'entry_screen.dart';

class DataDisplayScreen extends StatefulWidget {
  final DateTime date;

  DataDisplayScreen({required this.date});

  @override
  _DataDisplayScreenState createState() => _DataDisplayScreenState();
}

class _DataDisplayScreenState extends State<DataDisplayScreen> {
  List<int> _entries = [];
  int _total = 0;
  double _reward = 0.0;
  double _price = 0.09;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    setState(() {
      _price = prefs.getDouble('price') ?? 0.09;
      _entries = prefs.getStringList('${dateStr}_entries')?.map((e) => int.parse(e)).toList() ?? [];
      _calculateTotals();
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    await prefs.setStringList('${dateStr}_entries', _entries.map((e) => e.toString()).toList());
  }

  void _calculateTotals() {
    _total = _entries.fold(0, (sum, item) => sum + item);
    _reward = _total * _price;
  }

  void _editEntry(int index) {
    final controller = TextEditingController(text: _entries[index].toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('修改'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newValue = int.tryParse(controller.text);
                if (newValue != null && newValue > 0) {
                  setState(() {
                    _entries[index] = newValue;
                    _calculateTotals();
                  });
                  _saveData();
                }
                Navigator.pop(context);
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _deleteEntry(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除这条记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _entries.removeAt(index);
                  _calculateTotals();
                });
                _saveData();
                Navigator.pop(context);
              },
              child: Text('删除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy-MM-dd').format(widget.date)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('总量: $_total', style: TextStyle(fontSize: 18)),
                Text('报酬: ${_reward.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_entries[index].toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _editEntry(index),
                        child: Text('修改'),
                      ),
                      TextButton(
                        onPressed: () => _deleteEntry(index),
                        child: Text('删除'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newEntries = await Navigator.push<List<int>>(
            context,
            MaterialPageRoute(
              builder: (context) => EntryScreen(date: widget.date),
            ),
          );
          if (newEntries != null && newEntries.isNotEmpty) {
            setState(() {
              _entries.addAll(newEntries);
              _calculateTotals();
            });
            _saveData();
          }
        },
        label: Text('添加'),
        icon: Icon(Icons.add),
      ),
    );
  }
}
