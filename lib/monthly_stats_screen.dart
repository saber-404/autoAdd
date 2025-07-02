import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MonthlyStatsScreen extends StatefulWidget {
  final DateTime month;

  MonthlyStatsScreen({required this.month});

  @override
  _MonthlyStatsScreenState createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  List<Map<String, dynamic>> _dailyStats = [];
  double _price = 0.09;

  @override
  void initState() {
    super.initState();
    _loadMonthlyStats();
  }

  void _loadMonthlyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final monthStr = DateFormat('yyyy-MM').format(widget.month);
    final keys = prefs.getKeys();
    _price = prefs.getDouble('price') ?? 0.09;
    List<Map<String, dynamic>> stats = [];

    for (var key in keys) {
      if (key.startsWith(monthStr) && key.endsWith('_entries')) {
        final day = key.split('_').first;
        final entries = prefs.getStringList(key)?.map((e) => int.parse(e)).toList() ?? [];
        final total = entries.fold(0, (sum, item) => sum + item);
        final reward = total * _price;
        stats.add({'day': day, 'total': total, 'reward': reward});
      }
    }

    stats.sort((a, b) => a['day'].compareTo(b['day']));

    setState(() {
      _dailyStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('yyyy-MM').format(widget.month)} 统计'),
      ),
      body: ListView.builder(
        itemCount: _dailyStats.length,
        itemBuilder: (context, index) {
          final stat = _dailyStats[index];
          return ListTile(
            title: Text(stat['day']),
            trailing: Text('总量: ${stat['total']}单位, 报酬: ${stat['reward'].toStringAsFixed(2)}元'),
          );
        },
      ),
    );
  }
}