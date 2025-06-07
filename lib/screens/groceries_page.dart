import 'package:flutter/material.dart';

class GroceriesPage extends StatefulWidget {
  const GroceriesPage({Key? key}) : super(key: key);

  @override
  State<GroceriesPage> createState() => _GroceriesPageState();
}

class _GroceryItem {
  String name;
  bool done;
  _GroceryItem(this.name) : done = false;
}

class _GroceriesPageState extends State<GroceriesPage> {
  final List<_GroceryItem> _items = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _items.add(_GroceryItem(name.trim()));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      child: Column(
        children: [
          // input field with outlined border and integrated add button
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add Grocery Item',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addItem(_controller.text),
              ),
            ),
            onSubmitted: _addItem,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _items.map((item) {
                return CheckboxListTile(
                  value: item.done,
                  title: Text(item.name),
                  onChanged: (checked) {
                    setState(() {
                      item.done = checked ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 