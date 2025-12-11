import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/note_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/note_model.dart';
import '../../models/reminder_model.dart';
import '../notes/note_editor_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Hoy',
          ),
        ],
      ),
      body: Consumer2<NoteProvider, ReminderProvider>(
        builder: (context, noteProvider, reminderProvider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  final notes = noteProvider.getNotesWithReminders(day);
                  final reminders = reminderProvider.getRemindersForDay(day);
                  return [...notes, ...reminders];
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                locale: 'es_ES',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedDay != null
                    ? _buildEventList(
                        _selectedDay!,
                        noteProvider.getNotesWithReminders(_selectedDay!),
                        reminderProvider.getRemindersForDay(_selectedDay!),
                      )
                    : Center(
                        child: Text(
                          'Selecciona un día para ver eventos',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedDay != null ? _addEventForDay : null,
        child: const Icon(Icons.add),
        tooltip: 'Añadir evento',
      ),
    );
  }

  Widget _buildEventList(DateTime day, List<NoteModel> notes, List<Reminder> reminders) {
    if (notes.isEmpty && reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay eventos para ${DateFormat('dd MMM yyyy', 'es_ES').format(day)}',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (notes.isNotEmpty) ...[
          Text(
            'Notas con recordatorio',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...notes.map((note) => _buildNoteCard(note)),
          const SizedBox(height: 16),
        ],
        if (reminders.isNotEmpty) ...[
          Text(
            'Recordatorios',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...reminders.map((reminder) => _buildReminderCard(reminder)),
        ],
      ],
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.note,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(note.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content.length > 50 
                    ? '${note.content.substring(0, 50)}...' 
                    : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Hora: ${DateFormat('HH:mm').format(note.reminderAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _openNote(note),
        ),
        onTap: () => _openNote(note),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.alarm,
          color: reminder.isCompleted ? Colors.grey : Theme.of(context).primaryColor,
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
            color: reminder.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description.isNotEmpty)
              Text(
                reminder.description,
                style: TextStyle(
                  color: reminder.isCompleted ? Colors.grey : null,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Hora: ${DateFormat('HH:mm').format(reminder.reminderAt)}',
              style: TextStyle(
                fontSize: 12,
                color: reminder.isCompleted 
                    ? Colors.grey 
                    : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        trailing: Checkbox(
          value: reminder.isCompleted,
          onChanged: (value) {
            final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
            final updatedReminder = reminder.copyWith(isCompleted: value ?? false);
            reminderProvider.updateReminder(updatedReminder);
          },
        ),
      ),
    );
  }

  void _openNote(NoteModel note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }

  void _addEventForDay() {
    if (_selectedDay == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('Crear nota con recordatorio'),
              onTap: () {
                Navigator.pop(context);
                _createNoteWithReminder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Crear recordatorio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/agenda');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNoteWithReminder() {
    if (_selectedDay == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final note = NoteModel(
      id: '',
      userId: authProvider.currentUser?.id ?? '',
      title: '',
      content: '',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      reminderAt: DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }
}
