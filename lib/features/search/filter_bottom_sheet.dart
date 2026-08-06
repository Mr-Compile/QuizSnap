import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> availableFilters;
  final Set<String> selectedFilters;
  final Function(Set<String>) onApply;

  const FilterBottomSheet({
    super.key,
    required this.availableFilters,
    required this.selectedFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter',
                  style: AppTheme.textSmall,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedFilters.clear());
                      },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    ElevatedButton(
                      onPressed: () {
                        widget.onApply(_selectedFilters);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: widget.availableFilters.length,
              itemBuilder: (context, index) {
                final filter = widget.availableFilters[index];
                final isSelected = _selectedFilters.contains(filter);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedFilters.add(filter);
                      } else {
                        _selectedFilters.remove(filter);
                      }
                    });
                  },
                  title: Text(filter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
