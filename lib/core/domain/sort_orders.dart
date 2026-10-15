/// Ordering for user-sorted configuration lists (categories, fields).
///
/// Lists are stored with an integer `sortOrder` and read ordered by it. A
/// drag moves one item; afterwards the visible list is renumbered `0..n-1`
/// and only the documents whose number actually changed are written, so a
/// small move is a small batch.
abstract final class SortOrders {
  /// Moves the item at [oldIndex] so it ends up at [newIndex], the final
  /// position (Flutter's `ReorderableListView.onReorderItem` semantics, which
  /// already account for the removed item).
  static List<T> move<T>(List<T> items, int oldIndex, int newIndex) {
    final result = List<T>.of(items);
    if (oldIndex < 0 || oldIndex >= result.length) return result;
    final target = newIndex.clamp(0, result.length - 1);
    final item = result.removeAt(oldIndex);
    result.insert(target, item);
    return result;
  }

  /// Replaces, in [all], the members of the group (in their current slots)
  /// with [reorderedGroup], leaving every other item where it was. Used when
  /// a list is shown in sections (categories by kind) but numbered globally.
  static List<T> mergeGroup<T>(
    List<T> all,
    List<T> reorderedGroup,
    String Function(T item) id,
  ) {
    final groupIds = reorderedGroup.map(id).toSet();
    final queue = List<T>.of(reorderedGroup);
    return [
      for (final item in all)
        if (groupIds.contains(id(item))) queue.removeAt(0) else item,
    ];
  }

  /// `{id: newSortOrder}` for each item of [ordered] whose stored order is
  /// not already its index.
  static Map<String, int> changes<T>(
    List<T> ordered,
    String Function(T item) id,
    int Function(T item) current,
  ) => {
    for (var index = 0; index < ordered.length; index++)
      if (current(ordered[index]) != index) id(ordered[index]): index,
  };

  /// The order for a new (or unarchived) item: after everything else.
  static int next<T>(Iterable<T> items, int Function(T item) current) =>
      items.isEmpty
      ? 0
      : items.map(current).reduce((a, b) => a > b ? a : b) + 1;
}
