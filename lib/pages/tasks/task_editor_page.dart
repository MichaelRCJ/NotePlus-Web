import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/note.dart';

class TaskEditorPage extends StatefulWidget {
  final List<TaskItem>? initialTasks;

  const TaskEditorPage({super.key, this.initialTasks});

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  final _taskController = TextEditingController();
  final List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(TaskItem(title: title));
        _taskController.clear();
      });
    }
  }

  void _updateTask(int index, TaskItem task) {
    setState(() {
      _tasks[index] = task;
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => Navigator.of(context).pop(_tasks),
          ),
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
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'New task',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _tasks.length,
                onReorder: _reorderTasks,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskItemWidget(
                    key: ValueKey(task.id),
                    task: task,
                    onUpdate: (updatedTask) => _updateTask(index, updatedTask),
                    onDelete: () => _deleteTask(index),
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

class TaskItemWidget extends StatefulWidget {
  final TaskItem task;
  final Function(TaskItem) onUpdate;
  final VoidCallback onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  final _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.task.title;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onUpdate(widget.task.copyWith(title: _controller.text.trim()));
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _cancelEdit() {
    _controller.text = widget.task.title;
    setState(() {
      _isEditing = false;
    });
  }

  void _toggleComplete() {
    widget.onUpdate(widget.task.copyWith(isCompleted: !widget.task.isCompleted));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(
              value: widget.task.isCompleted,
              onChanged: (_) => _toggleComplete(),
            ),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _saveEdit(),
                    )
                  : Text(
                      widget.task.title,
                      style: TextStyle(
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.task.isCompleted ? Colors.grey : null,
                      ),
                    ),
            ),
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveEdit,
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _cancelEdit,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _startEditing,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: widget.onDelete,
              ),
            ],
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}
