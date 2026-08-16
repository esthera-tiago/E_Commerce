import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filter_state.dart';
import '../providers/product_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final categories = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          // Search field
          TextField(
            onChanged: (v) =>
                ref.read(filterProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          ref.read(filterProvider.notifier).setSearch(''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          // Category chips + sort button
          categories.when(
            data: (cats) => Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final label = isAll ? 'Tout' : cats[i - 1];
                        final selected =
                            isAll ? filter.category.isEmpty : filter.category == label;

                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => ref
                              .read(filterProvider.notifier)
                              .setCategory(isAll ? '' : label),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Trier',
                  onSelected: (v) =>
                      ref.read(filterProvider.notifier).setSort(v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: SortOption.newest, child: Text('Recents')),
                    PopupMenuItem(
                        value: SortOption.priceAsc, child: Text('Prix croissant')),
                    PopupMenuItem(
                        value: SortOption.priceDesc, child: Text('Prix decroissant')),
                    PopupMenuItem(
                        value: SortOption.rating, child: Text('Meilleures notes')),
                  ],
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
