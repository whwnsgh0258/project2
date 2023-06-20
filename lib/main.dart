import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _events = (prefs.getStringList('events')?.map(
            (event) => MapEntry(
          DateTime.parse(event.split('::')[0]),
          event.split('::')[1].split(';;'),
        ),
      ) ?? {}) as Map<DateTime, List<String>>;
    });
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _addEvent(DateTime day, String event) {
    setState(() {
      _events.update(day, (value) => [...value, event], ifAbsent: () => [event]);
      _saveEvents();
    });
  }

  void _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> eventList = _events.entries.map((entry) {
      String key = entry.key.toIso8601String();
      String value = entry.value.join(';;');
      return '$key::$value';
    }).toList();
    prefs.setStringList('events', eventList);
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2023, 12, 31),
      focusedDay: _selectedDay,
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarStyle: CalendarStyle(
        selectedTextStyle: TextStyle(color: Colors.white),
        todayTextStyle: TextStyle(color: Colors.blue),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildEventList() {
    List<String> events = _getEventsForDay(_selectedDay);
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(events[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar App'),
      ),
      body: Column(
        children: [
          _buildTableCalendar(),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String? newEvent;
              return AlertDialog(
                title: Text('Add Event'),
                content: TextField(
                  onChanged: (value) {
                    newEvent = value;
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (newEvent != null) {
                        _addEvent(_selectedDay, newEvent!);
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
