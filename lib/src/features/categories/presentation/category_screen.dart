import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';
import '../../../data/database.dart'; // For Category type

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Income"),
            Tab(text: "Expense"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryList(type: 'INCOME'),
          _CategoryList(type: 'EXPENSE'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Determine type based on active tab
          final type = _tabController.index == 0 ? 'INCOME' : 'EXPENSE';
          _showCategoryDialog(context, type: type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {required String type, Category? categoryToEdit}) {
    final controller = TextEditingController(text: categoryToEdit?.name ?? "");
    final isEditing = categoryToEdit != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Edit Category" : "New $type Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Category Name", border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) return;

              if (isEditing) {
                ref.read(categoryRepositoryProvider.notifier).updateCategory(
                  id: categoryToEdit.id,
                  name: controller.text,
                  type: type,
                );
              } else {
                ref.read(categoryRepositoryProvider.notifier).addCategory(
                  controller.text,
                  type,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final String type;
  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = type == 'INCOME' ? incomeCategoriesProvider : expenseCategoriesProvider;
    final categoriesAsync = ref.watch(provider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text("No categories found."));
        }
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: type == 'INCOME' ? Colors.green[50] : Colors.red[50],
                child: Icon(
                  type == 'INCOME' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: type == 'INCOME' ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              title: Text(cat.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // Find the parent state to show dialog
                      context.findAncestorStateOfType<_CategoryScreenState>()
                          ?._showCategoryDialog(context, type: type, categoryToEdit: cat);
                    },
                  ),
                  if (!cat.isSystem) // Prevent deleting system categories if you want
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, cat),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete '${cat.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(categoryRepositoryProvider.notifier).deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}