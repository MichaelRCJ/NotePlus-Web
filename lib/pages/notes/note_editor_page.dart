import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../providers/auth_provider.dart';
import '../drawing/drawing_page.dart';

class NoteEditorPage extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _categoryController = TextEditingController();
  
  List<String> _tags = [];
  List<TaskItem> _tasks = [];
  List<String> _attachments = [];
  bool _isPinned = false;
  Color? _backgroundColor;
  DateTime? _reminderAt;
  String? _drawingData;

  @override
  void initState() {
    super.initState();
    if (widget.note != null && widget.note!.id.isNotEmpty) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tags = List.from(widget.note!.tags);
      _categoryController.text = widget.note!.category;
      _isPinned = widget.note!.isPinned;
      _backgroundColor = widget.note!.backgroundColor;
      _reminderAt = widget.note!.reminderAt;
      _tasks = List.from(widget.note!.tasks);
      _attachments = List.from(widget.note!.attachments);
      _drawingData = widget.note!.drawingData;
    } else if (widget.note != null && widget.note!.reminderAt != null) {
      _reminderAt = widget.note!.reminderAt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic text colors based on background
    final isLightBg = _backgroundColor != null && _isLightColor(_backgroundColor!);
    final titleColor = isLightBg ? const Color(0xFF1A1F36) : Colors.white;
    final contentColor = isLightBg ? const Color(0xFF4A5568) : const Color(0xFFE5E7EB);
    final hintColor = isLightBg ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    
    return Scaffold(
      backgroundColor: _backgroundColor ?? const Color(0xFF1A1D29),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF252836),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.note == null ? 'Nueva Nota' : 'Editar Nota',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? const Color(0xFF6366F1) : Colors.white,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: _isPinned ? 'Desfijar' : 'Fijar',
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            onPressed: _saveNote,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Container(
        color: _backgroundColor ?? const Color(0xFF1A1D29),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Título de la nota',
                  hintStyle: GoogleFonts.inter(
                    color: hintColor,
                    fontSize: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              
              // Content
              TextField(
                controller: _contentController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: contentColor,
                  height: 1.5,
                ),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Escribe tu nota aquí...',
                  hintStyle: GoogleFonts.inter(
                    color: hintColor,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),

              // Category with predefined options
              _buildCategorySection(),
              const SizedBox(height: 16),

              // Tags
              _buildTagsSection(),
              const SizedBox(height: 16),

              // Tasks
              _buildTasksSection(),
              const SizedBox(height: 16),

              // Drawing
              if (_drawingData != null) ...[
                _buildDrawingPreview(),
                const SizedBox(height: 16),
              ],

              // Attachments
              if (_attachments.isNotEmpty) ...[
                _buildAttachmentsSection(),
                const SizedBox(height: 16),
              ],

              // Options
              _buildOptionsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMoreOptions,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Más opciones',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8E95A9),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StudentCategories.categories.map((category) {
            final isSelected = _categoryController.text == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _categoryController.text = selected ? category : '';
                });
              },
              backgroundColor: const Color(0xFF252836),
              selectedColor: const Color(0xFF6366F1),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : const Color(0xFF8E95A9),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Añadir etiqueta',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: const Color(0xFF252836),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D3142)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D3142)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF6366F1)),
              onPressed: _addTag,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF252836),
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag, style: GoogleFonts.inter(color: Colors.white)),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
              backgroundColor: const Color(0xFF6366F1),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTasksSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3142), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checklist_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tareas',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddTaskDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Añadir', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.task_alt_rounded, size: 48, color: const Color(0xFF6B7280)),
                    const SizedBox(height: 12),
                    Text(
                      'No hay tareas',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return _buildTaskItem(task, index);
            }),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskItem task, int index) {
    final isOverdue = task.dueDate != null && 
                      task.dueDate!.isBefore(DateTime.now()) && 
                      !task.isCompleted;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.3) : const Color(0xFF2D3142),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) => _toggleTask(index),
                activeColor: const Color(0xFF6366F1),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted ? const Color(0xFF6B7280) : Colors.white,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF8E95A9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8E95A9), size: 20),
                color: const Color(0xFF252836),
                onSelected: (value) {
                  if (value == 'edit') _editTask(index);
                  if (value == 'delete') _removeTask(index);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF8E95A9)),
                        const SizedBox(width: 8),
                        Text('Editar', style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text('Eliminar', style: GoogleFonts.inter(color: Colors.red.shade400, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Task Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.type.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Priority
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 12, color: task.priorityColor),
                    const SizedBox(width: 4),
                    Text(
                      'Prioridad ${task.priority}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: task.priorityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Start Date
              if (task.startDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3142),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 12, color: Color(0xFF8E95A9)),
                      const SizedBox(width: 4),
                      Text(
                        'Inicio: ${DateFormat('dd/MM').format(task.startDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8E95A9),
                        ),
                      ),
                    ],
                  ),
                ),
              // Due Date
              if (task.dueDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red.withOpacity(0.15) : const Color(0xFF2D3142),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 12,
                        color: isOverdue ? Colors.red : const Color(0xFF8E95A9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vence: ${DateFormat('dd/MM').format(task.dueDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : const Color(0xFF8E95A9),
                        ),
                      ),
                    ],
                  ),
                ),
              // Attachments count
              if (task.attachments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3142),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF8E95A9)),
                      const SizedBox(width: 4),
                      Text(
                        '${task.attachments.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8E95A9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3142), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.draw_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Dibujo',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
                  onPressed: _editDrawing,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => setState(() => _drawingData = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_drawingData != null && _drawingData!.startsWith('data:image')) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D3142)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_drawingData!.split(',')[1]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3142), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Adjuntos',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.map((attachment) {
                final parts = attachment.split('|');
                final fileName = parts.isNotEmpty ? parts[0] : attachment;
                return Chip(
                  avatar: const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF6366F1)),
                  label: Text(
                    fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  ),
                  onDeleted: () => _removeAttachment(attachment),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  backgroundColor: const Color(0xFF6366F1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3142), width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens_rounded, color: Color(0xFF6366F1)),
            title: Text('Color de fondo', style: GoogleFonts.inter(color: Colors.white)),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _backgroundColor ?? const Color(0xFF1A1D29),
                border: Border.all(color: const Color(0xFF2D3142)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onTap: _showColorPicker,
          ),
          const Divider(color: Color(0xFF2D3142), height: 1),
          ListTile(
            leading: const Icon(Icons.alarm_rounded, color: Color(0xFF6366F1)),
            title: Text(
              _reminderAt == null 
                  ? 'Añadir recordatorio' 
                  : 'Recordatorio: ${DateFormat('dd/MM/yyyy HH:mm').format(_reminderAt!)}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            trailing: _reminderAt != null
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8E95A9)),
                    onPressed: () => setState(() => _reminderAt = null),
                  )
                : null,
            onTap: _setReminder,
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddTaskDialog() {
    _showTaskEditorDialog();
  }

  void _editTask(int index) {
    _showTaskEditorDialog(task: _tasks[index], index: index);
  }

  void _showTaskEditorDialog({TaskItem? task, int? index}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    TaskType selectedType = task?.type ?? TaskType.other;
    DateTime? startDate = task?.startDate;
    DateTime? dueDate = task?.dueDate;
    int priority = task?.priority ?? 3;
    List<String> taskAttachments = List.from(task?.attachments ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252836),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            task == null ? 'Nueva Tarea' : 'Editar Tarea',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Título de la tarea',
                      labelStyle: GoogleFonts.inter(color: const Color(0xFF8E95A9)),
                      filled: true,
                      fillColor: const Color(0xFF1F2332),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D3142)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    style: GoogleFonts.inter(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: GoogleFonts.inter(color: const Color(0xFF8E95A9)),
                      filled: true,
                      fillColor: const Color(0xFF1F2332),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D3142)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tipo de tarea',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E95A9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskType.values.map((type) {
                      final isSelected = selectedType == type;
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() => selectedType = type);
                        },
                        backgroundColor: const Color(0xFF1F2332),
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.white : const Color(0xFF8E95A9),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.play_arrow_rounded, color: Color(0xFF6366F1)),
                          title: Text(
                            'Fecha de inicio',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            startDate != null
                                ? DateFormat('dd/MM/yyyy').format(startDate!)
                                : 'No establecida',
                            style: GoogleFonts.inter(color: const Color(0xFF8E95A9), fontSize: 12),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => startDate = date);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_rounded, color: Color(0xFF6366F1)),
                          title: Text(
                            'Fecha de vencimiento',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            dueDate != null
                                ? DateFormat('dd/MM/yyyy').format(dueDate!)
                                : 'No establecida',
                            style: GoogleFonts.inter(color: const Color(0xFF8E95A9), fontSize: 12),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => dueDate = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prioridad',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E95A9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: 'Prioridad $priority',
                    activeColor: _getPriorityColor(priority),
                    onChanged: (value) {
                      setDialogState(() => priority = value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  if (taskAttachments.isNotEmpty) ...[
                    Text(
                      'Adjuntos',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E95A9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: taskAttachments.map((att) {
                        final fileName = att.split('|').first;
                        return Chip(
                          label: Text(fileName, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                          onDeleted: () {
                            setDialogState(() => taskAttachments.remove(att));
                          },
                          backgroundColor: const Color(0xFF6366F1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: false,
                        );
                        if (result != null && result.files.single.bytes != null) {
                          final file = result.files.single;
                          final bytes = file.bytes!;
                          final base64String = base64Encode(bytes);
                          final fileData = 'data:${file.extension};base64,$base64String';
                          setDialogState(() {
                            taskAttachments.add('${file.name}|$fileData');
                          });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Adjuntar archivo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF8E95A9))),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El título es requerido')),
                  );
                  return;
                }
                final newTask = TaskItem(
                  id: task?.id ?? const Uuid().v4(),
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  type: selectedType,
                  startDate: startDate,
                  dueDate: dueDate,
                  priority: priority,
                  attachments: taskAttachments,
                  createdAt: task?.createdAt ?? DateTime.now(),
                  isCompleted: task?.isCompleted ?? false,
                );
                setState(() {
                  if (index != null) {
                    _tasks[index] = newTask;
                  } else {
                    _tasks.add(newTask);
                  }
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 2:
        return Colors.blue;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _editDrawing() async {
    final drawing = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => DrawingPage(initialDrawing: _drawingData),
      ),
    );

    if (drawing != null) {
      setState(() {
        _drawingData = drawing;
      });
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252836),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw_rounded, color: Color(0xFF6366F1)),
              title: Text('Añadir dibujo', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _addDrawing();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF6366F1)),
              title: Text('Adjuntar archivo', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _attachFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: Color(0xFF6366F1)),
              title: Text('Añadir tarea', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAddTaskDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addDrawing() async {
    final drawing = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const DrawingPage(),
      ),
    );

    if (drawing != null) {
      setState(() {
        _drawingData = drawing;
      });
    }
  }

  Future<void> _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final bytes = file.bytes!;
        final base64String = base64Encode(bytes);
        final fileData = 'data:${file.extension};base64,$base64String';
        
        setState(() {
          _attachments.add('${file.name}|$fileData');
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al adjuntar archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(String attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Seleccionar color', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _backgroundColor ?? const Color(0xFF1A1D29),
            onColorChanged: (color) => setState(() => _backgroundColor = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _backgroundColor = null),
            child: Text('Sin color', style: GoogleFonts.inter(color: const Color(0xFF8E95A9))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Listo', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _setReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
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

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa un título', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No hay usuario autenticado', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final note = NoteModel(
      id: (widget.note != null && widget.note!.id.isNotEmpty) 
          ? widget.note!.id 
          : const Uuid().v4(),
      userId: authProvider.currentUser!.id,
      title: title,
      content: content,
      createdAt: (widget.note != null && widget.note!.id.isNotEmpty)
          ? widget.note!.createdAt
          : DateTime.now(),
      modifiedAt: DateTime.now(),
      tags: _tags,
      category: _categoryController.text.trim(),
      isPinned: _isPinned,
      backgroundColor: _backgroundColor,
      reminderAt: _reminderAt,
      tasks: _tasks,
      attachments: _attachments,
      drawingData: _drawingData,
    );

    try {
      if (widget.note == null || widget.note!.id.isEmpty) {
        await noteProvider.addNote(note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota guardada correctamente', style: GoogleFonts.inter()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await noteProvider.updateNote(note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nota actualizada correctamente', style: GoogleFonts.inter()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la nota: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
