import 'package:business_ledger/core/domain/sort_orders.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Item = ({String id, int order});

void main() {
  List<_Item> items(List<String> ids) => [
    for (var i = 0; i < ids.length; i++) (id: ids[i], order: i),
  ];
  String id(_Item item) => item.id;
  int order(_Item item) => item.order;

  test('move takes the final index (onReorderItem semantics)', () {
    expect(SortOrders.move(['a', 'b', 'c', 'd'], 0, 2), ['b', 'c', 'a', 'd']);
    expect(SortOrders.move(['a', 'b', 'c', 'd'], 3, 0), ['d', 'a', 'b', 'c']);
    expect(SortOrders.move(['a', 'b'], 0, 9), ['b', 'a']);
    expect(SortOrders.move(['a', 'b'], 5, 0), ['a', 'b']);
  });

  test('changes lists only the items whose order moved', () {
    final moved = SortOrders.move(items(['a', 'b', 'c', 'd']), 1, 2);
    expect(SortOrders.changes(moved, id, order), {'c': 1, 'b': 2});
  });

  test('changes renumbers gaps and duplicates from zero', () {
    final list = <_Item>[(id: 'a', order: 5), (id: 'b', order: 5)];
    expect(SortOrders.changes(list, id, order), {'a': 0, 'b': 1});
  });

  test('mergeGroup reorders a section in place, others untouched', () {
    final all = ['i1', 'e1', 'i2', 'e2', 'e3'];
    final merged = SortOrders.mergeGroup(all, ['e3', 'e1', 'e2'], (s) => s);
    expect(merged, ['i1', 'e3', 'i2', 'e1', 'e2']);
  });

  test('next goes after the largest order', () {
    expect(SortOrders.next(<_Item>[], order), 0);
    expect(
      SortOrders.next(<_Item>[(id: 'a', order: 2), (id: 'b', order: 7)], order),
      8,
    );
  });
}
