import 'package:flexify/database/gym_sets.dart';
import 'package:flutter/material.dart';

class GraphsFilters extends StatefulWidget {
  final String? category;
  final Function(String?) setCategory;

  const GraphsFilters({
    super.key,
    required this.category,
    required this.setCategory,
  });

  @override
  createState() => _GraphsFiltersState();
}

class _GraphsFiltersState extends State<GraphsFilters> {
  int get count => (widget.category != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: StreamBuilder(
        stream: categoriesStream,
        builder: (context, snapshot) {
          return PopupMenuButton(
            padding: EdgeInsets.zero,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: widget.category,
                  items: snapshot.data
                      ?.map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    widget.setCategory(value);
                    Navigator.pop(context);
                  },
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text("Clear"),
                  onTap: () async {
                    widget.setCategory(null);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
            tooltip: "Filter by category",
            icon: Icon(
              Icons.filter_list,
              color: count > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
