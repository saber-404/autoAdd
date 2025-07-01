
import 'package:autoadd/monthly_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'data_display_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _monthlyTotal = 0;
  double _monthlyReward = 0.0;
  double _price = 0.09;
  String _monthLabel = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateMonthLabel();
    _loadMonthlyData();
  }

  void _updateMonthLabel() {
    _monthLabel = DateFormat('M月').format(_focusedDay);
  }

  void _loadMonthlyData() async {
    final prefs = await SharedPreferences.getInstance();
    final month = DateFormat('yyyy-MM').format(_focusedDay);
    final keys = prefs.getKeys();
    int total = 0;
    _price = prefs.getDouble('price') ?? 0.09;

    for (var key in keys) {
      if (key.startsWith(month) && key.endsWith('_entries')) {
        final entries = prefs.getStringList(key)?.map((e) => int.parse(e)).toList() ?? [];
        total += entries.fold(0, (sum, item) => sum + item);
      }
    }

    setState(() {
      _monthlyTotal = total;
      _monthlyReward = total * _price;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _focusedDay,
        firstDate: DateTime(2020, 1),
        lastDate: DateTime(2030, 12),
        locale: const Locale('zh', 'CN'));
    if (picked != null && picked != _focusedDay) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
        _updateMonthLabel();
      });
      _loadMonthlyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('拣货记录'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) => _loadMonthlyData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'zh_CN',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DataDisplayScreen(date: selectedDay),
                ),
              ).then((_) {
                _loadMonthlyData();
                _updateMonthLabel();
              });
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _updateMonthLabel();
              });
              _loadMonthlyData();
            },
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonthlyStatsScreen(month: _focusedDay),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text('$_monthLabel拣货: $_monthlyTotal', style: TextStyle(fontSize: 20)),
                  Text('$_monthLabel报酬: ${_monthlyReward.toStringAsFixed(2)}', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
