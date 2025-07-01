
import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EntryScreen extends StatefulWidget {
  final DateTime date;

  EntryScreen({required this.date});
  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  // final _speech = stt.SpeechToText();
  final _controller = TextEditingController();
  List<int> _entries = [];
  // bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // _speech.initialize();
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    await prefs.setStringList('${dateStr}_entries', _entries.map((e) => e.toString()).toList());
  }

  void _addEntry() {
    final value = int.tryParse(_controller.text);
    if (value != null && value > 0) {
      setState(() {
        _entries.add(value);
        _controller.clear();
      });
      _saveData(); // 每次添加后保存数据
    }
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
                  });
                  _saveData(); // 修改后保存数据
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
    setState(() {
      _entries.removeAt(index);
    });
    _saveData(); // 删除后保存数据
  }

  /*
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('录入数据'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _entries); // 返回数据给上一页
            },
            child: Text('完成', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: '输入数量'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                // TextButton(
                //   onPressed: _listen,
                //   child: Text(_isListening ? '停止' : '语音'),
                // ),
                ElevatedButton(
                  onPressed: _addEntry,
                  child: Text('添加'),
                ),
              ],
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
      ),
    );
  }
}
