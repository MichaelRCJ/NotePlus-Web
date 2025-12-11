import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../providers/theme_provider.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = note.backgroundColor ?? Theme.of(context).cardTheme.color ?? const Color(0xFF252836);
    final isLightBg = _isLightColor(bgColor);
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    
    // Dynamic text colors based on background
    final titleColor = isLightBg ? const Color(0xFF1A1F36) : Theme.of(context).colorScheme.onSurface;
    final contentColor = isLightBg ? const Color(0xFF4A5568) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    final subtitleColor = isLightBg ? const Color(0xFF6B7280) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = note.isPinned 
        ? primaryColor 
        : (isLightBg ? Colors.grey.shade300 : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2));
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: note.isPinned ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isLightBg ? null : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                bgColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and pin
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Content preview
              Expanded(
                child: Text(
                  note.content,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: contentColor,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tags
              if (note.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Tasks indicator with more info
              if (note.tasks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 12,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${note.tasks.where((t) => t.isCompleted).length}/${note.tasks.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show overdue tasks warning
                if (note.tasks.any((t) => t.dueDate != null && 
                    t.dueDate!.isBefore(DateTime.now()) && 
                    !t.isCompleted)) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded, size: 10, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Tareas vencidas',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              // Category
              if (note.category.isNotEmpty) ...[
                if (note.tasks.isNotEmpty) const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              
              // Drawing indicator
              if (note.drawingData != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.draw_rounded,
                      size: 14,
                      color: const Color(0xFF8E95A9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dibujo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8E95A9),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Attachments indicator
              if (note.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      size: 14,
                      color: const Color(0xFF8E95A9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.attachments.length} adjunto${note.attachments.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8E95A9),
                      ),
                    ),
                  ],
                ),
              ],
              
              const Spacer(),
              
              // Footer with date and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLightBg ? Colors.grey.shade100 : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('d MMM', 'es_ES').format(note.modifiedAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (note.reminderAt != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.alarm_rounded,
                            size: 12,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: subtitleColor),
                    color: Theme.of(context).cardTheme.color,
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text('Eliminar', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar nota', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${note.title}"?',
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
