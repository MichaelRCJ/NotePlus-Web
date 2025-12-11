import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/reminder_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../models/reminder_model.dart';
import '../models/note_model.dart';
import '../pages/notes/note_editor_page.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      reminderProvider.setCurrentUserId(authProvider.currentUser!.id);
      noteProvider.setCurrentUserId(authProvider.currentUser!.id);
    }
    reminderProvider.loadReminders();
    noteProvider.loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252836),
        elevation: 0,
        title: Text(
          'Mi Agenda',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Vista de lista' : 'Vista de cuadrícula',
          ),
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
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
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2332),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3142)),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar tareas o eventos...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF252836),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2D3142)),
            ),
            child: Consumer2<ReminderProvider, NoteProvider>(
              builder: (context, reminderProvider, noteProvider, child) {
                return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    final reminders = reminderProvider.getRemindersForDay(day);
                    final notes = noteProvider.getNotesWithReminders(day);
                    return [...reminders, ...notes];
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
                    markersMaxCount: 4,
                    markerDecoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                    selectedTextStyle: GoogleFonts.inter(color: Colors.white),
                    todayTextStyle: GoogleFonts.inter(color: Colors.white),
                    weekendTextStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                    outsideTextStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonTextStyle: GoogleFonts.inter(color: const Color(0xFF6366F1)),
                    titleTextStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                    weekendStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  ),
                  locale: 'es_ES',
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tasks for selected day
          Expanded(
            child: _buildTasksForSelectedDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _addTask,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTasksForSelectedDay() {
    return Consumer2<ReminderProvider, NoteProvider>(
      builder: (context, reminderProvider, noteProvider, child) {
        if (_selectedDay == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 64,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona un día para ver tus tareas',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final reminders = reminderProvider.getRemindersForDay(_selectedDay!);
        final notes = noteProvider.getNotesWithReminders(_selectedDay!);
        final allTasks = [...reminders, ...notes];
        
        // Apply search filter
        final searchTerm = _searchController.text.toLowerCase();
        final filteredTasks = searchTerm.isEmpty 
            ? allTasks
            : allTasks.where((task) {
                if (task is Reminder) {
                  return task.title.toLowerCase().contains(searchTerm) ||
                         task.description.toLowerCase().contains(searchTerm);
                } else if (task is NoteModel) {
                  return task.title.toLowerCase().contains(searchTerm) ||
                         task.content.toLowerCase().contains(searchTerm);
                }
                return false;
              }).toList();

        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 64,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(height: 16),
                Text(
                  searchTerm.isEmpty 
                      ? 'No hay tareas para ${DateFormat('d MMM', 'es_ES').format(_selectedDay!)}'
                      : 'No se encontraron resultados',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                ),
                if (searchTerm.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar una tarea',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Header with date and task count
        final header = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF252836),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D3142)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDay!),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredTasks.length} ${filteredTasks.length == 1 ? 'tarea' : 'tareas'}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isGridView ? 'Cuadrícula' : 'Lista',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (_isGridView) {
          return Column(
            children: [
              header,
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    if (task is Reminder) {
                      return _buildReminderGridCard(task);
                    } else if (task is NoteModel) {
                      return _buildNoteGridCard(task);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              header,
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    if (task is Reminder) {
                      return _buildReminderListCard(task);
                    } else if (task is NoteModel) {
                      return _buildNoteListCard(task);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildReminderGridCard(Reminder reminder) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isCompleted 
              ? const Color(0xFF2D3142) 
              : const Color(0xFF6366F1).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editReminder(reminder),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reminder.isCompleted 
                          ? const Color(0xFF2D3142)
                          : const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.alarm_rounded,
                      size: 20,
                      color: reminder.isCompleted 
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF6366F1),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _toggleReminder(reminder),
                    child: Icon(
                      reminder.isCompleted 
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 24,
                      color: reminder.isCompleted 
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reminder.title,
                style: GoogleFonts.inter(
                  color: reminder.isCompleted 
                      ? const Color(0xFF6B7280)
                      : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: reminder.isCompleted 
                      ? TextDecoration.lineThrough 
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (reminder.description.isNotEmpty) ...[
                Text(
                  reminder.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(reminder.reminderAt),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteGridCard(NoteModel note) {
    return Container(
      decoration: BoxDecoration(
        color: note.backgroundColor ?? const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNote(note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.note_rounded,
                      size: 20,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const Spacer(),
                  if (note.isPinned)
                    const Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              if (note.reminderAt != null)
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(note.reminderAt!),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderListCard(Reminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.isCompleted 
              ? const Color(0xFF2D3142) 
              : const Color(0xFF6366F1).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: GestureDetector(
          onTap: () => _toggleReminder(reminder),
          child: Icon(
            reminder.isCompleted 
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 24,
            color: reminder.isCompleted 
                ? const Color(0xFF6366F1)
                : const Color(0xFF6B7280),
          ),
        ),
        title: Text(
          reminder.title,
          style: GoogleFonts.inter(
            color: reminder.isCompleted 
                ? const Color(0xFF6B7280)
                : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: reminder.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reminder.description,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(reminder.reminderAt),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
          color: const Color(0xFF252836),
          onSelected: (value) {
            if (value == 'edit') {
              _editReminder(reminder);
            } else if (value == 'delete') {
              _deleteReminder(reminder.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListCard(NoteModel note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: note.backgroundColor ?? const Color(0xFF252836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.note_rounded,
            size: 20,
            color: Color(0xFF6366F1),
          ),
        ),
        title: Text(
          note.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.content,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (note.isPinned) ...[
                  Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 4),
                ],
                if (note.reminderAt != null) ...[
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(note.reminderAt!),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
          color: const Color(0xFF252836),
          onSelected: (value) {
            if (value == 'edit') {
              _openNote(note);
            } else if (value == 'delete') {
              _deleteNote(note.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    if (_selectedDay == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: Text(
          'Agregar tarea',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.alarm_rounded, color: Color(0xFF6366F1)),
              title: Text(
                'Crear recordatorio',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _createReminder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_rounded, color: Color(0xFF6366F1)),
              title: Text(
                'Crear nota con recordatorio',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _createNoteWithReminder();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createReminder() {
    if (_selectedDay == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: '',
      description: '',
      reminderAt: DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
      isCompleted: false,
      isTriggered: false,
      noteId: '',
      userId: authProvider.currentUser?.id ?? '',
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReminderEditorPage(reminder: reminder),
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

  void _editReminder(Reminder reminder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReminderEditorPage(reminder: reminder),
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

  void _deleteReminder(String reminderId) async {
    await Provider.of<ReminderProvider>(context, listen: false).deleteReminder(reminderId);
  }

  void _deleteNote(String noteId) async {
    await Provider.of<NoteProvider>(context, listen: false).deleteNote(noteId);
  }

  void _toggleReminder(Reminder reminder) async {
    final updatedReminder = reminder.copyWith(isCompleted: !reminder.isCompleted);
    await Provider.of<ReminderProvider>(context, listen: false).updateReminder(updatedReminder);
  }
}

// Reminder Editor Page
class ReminderEditorPage extends StatefulWidget {
  final Reminder? reminder;

  const ReminderEditorPage({super.key, this.reminder});

  @override
  State<ReminderEditorPage> createState() => _ReminderEditorPageState();
}

class _ReminderEditorPageState extends State<ReminderEditorPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _reminderAt = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _reminderAt = widget.reminder!.reminderAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252836),
        elevation: 0,
        title: Text(
          widget.reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveReminder,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2332),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D3142)),
              ),
              child: TextField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2332),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D3142)),
              ),
              child: TextField(
                controller: _descriptionController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2332),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D3142)),
              ),
              child: ListTile(
                title: Text(
                  'Fecha y Hora',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(_reminderAt),
                  style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                onTap: _selectDateTime,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderAt),
      );

      if (time != null) {
        setState(() {
          _reminderAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor ingresa un título',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reminder = Reminder(
      id: widget.reminder?.id ?? const Uuid().v4(),
      title: title,
      description: _descriptionController.text.trim(),
      reminderAt: _reminderAt,
      isCompleted: widget.reminder?.isCompleted ?? false,
      isTriggered: widget.reminder?.isTriggered ?? false,
      noteId: widget.reminder?.noteId ?? '',
      userId: authProvider.currentUser?.id ?? '',
    );

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    if (widget.reminder == null) {
      await reminderProvider.addReminder(reminder);
    } else {
      await reminderProvider.updateReminder(reminder);
    }

    Navigator.of(context).pop();
  }
}
