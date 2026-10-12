import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PunuAI Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoItem {
  TodoItem({required this.title, this.done = false});

  final String title;
  bool done;

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  static const _storageKey = 'punuai_todo_items';

  final List<TodoItem> _items = [];
  final TextEditingController _controller = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items.addAll(
        decoded.map((e) => TodoItem.fromJson(e as Map<String, dynamic>)),
      );
    }
    setState(() => _loaded = true);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(TodoItem(title: text));
      _controller.clear();
    });
    _saveItems();
  }

  void _toggleItem(int index, bool? value) {
    setState(() => _items[index].done = value ?? false);
    _saveItems();
  }

  void _deleteItem(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    _saveItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _items.insert(index, removed));
            _saveItems();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _items.where((e) => e.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PunuAI Todo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a new task...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addItem,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$doneCount of ${_items.length} done',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks yet.\nAdd your first one above!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Dismissible(
                            key: ValueKey('${item.title}-$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteItem(index),
                            child: CheckboxListTile(
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  decoration: item.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              value: item.done,
                              onChanged: (v) => _toggleItem(index, v),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteItem(index),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
