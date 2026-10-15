import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

/// [ReportsRepository] over Firestore. Every query here is backed by an
/// index in `firestore.indexes.json` (or is single-field).
@LazySingleton(as: ReportsRepository)
class ReportsService implements ReportsRepository {
  ReportsService(this._refs);

  final FirestoreRefs _refs;

  /// `dateTs` is the day at UTC midnight (`functions/src/lib/dates.ts`).
  static Timestamp _dayTs(String day) =>
      Timestamp.fromDate(CalendarDay.parse(day));

  @override
  Stream<AppResult<List<DailyStats>>> watchStats(
    String businessId, {
    required String from,
    required String to,
  }) => _refs
      .stats(businessId)
      .where('dateTs', isGreaterThanOrEqualTo: _dayTs(from))
      .where('dateTs', isLessThanOrEqualTo: _dayTs(to))
      .orderBy('dateTs')
      .snapshots()
      .transform(
        _results(
          (snapshot) => [
            for (final doc in snapshot.docs)
              DailyStats.fromMap(doc.id, doc.data()),
          ],
        ),
      );

  Query<JsonMap> _open(String businessId, Direction? direction) {
    var query = _refs.transactions(businessId).where('isOpen', isEqualTo: true);
    if (direction != null) {
      query = query.where('direction', isEqualTo: direction.key);
    }
    return query;
  }

  @override
  Future<AppResult<ReceivablesPayables>> receivablesAndPayables(
    String businessId,
  ) async {
    try {
      final [receivable, payable] = await Future.wait([
        for (final direction in Direction.values)
          _open(businessId, direction)
              .aggregate(sum('outstandingMinor'))
              .get()
              .then((snapshot) => snapshot.getSum('outstandingMinor')),
      ]);
      return Success(
        ReceivablesPayables(
          // Sums of integers, exact below 2^53.
          receivableMinor: (receivable ?? 0).round(),
          payableMinor: (payable ?? 0).round(),
        ),
      );
    } catch (error) {
      final failure = AppException.from(error);
      // Aggregates are server-only; offline, sum what the cache holds.
      if (!failure.isOffline && failure.kind != AppErrorKind.timeout) {
        return Failure(failure);
      }
      return AppResult.guard(() => _fromCache(businessId));
    }
  }

  Future<ReceivablesPayables> _fromCache(String businessId) async {
    final snapshot = await _open(
      businessId,
      null,
    ).get(const GetOptions(source: Source.cache));
    var receivable = 0;
    var payable = 0;
    for (final doc in snapshot.docs) {
      final row = TransactionRow.fromMap(doc.id, doc.data());
      if (row.direction == Direction.outflow) {
        payable += row.outstandingMinor;
      } else {
        receivable += row.outstandingMinor;
      }
    }
    return ReceivablesPayables(
      receivableMinor: receivable,
      payableMinor: payable,
      fromCache: true,
    );
  }

  @override
  Stream<AppResult<List<TransactionRow>>> openTransactions(
    String businessId, {
    Direction? direction,
    bool overdueOnly = false,
    String? today,
    int limit = 20,
  }) {
    var query = _open(businessId, direction);
    if (overdueOnly) {
      query = query.where(
        'dueDate',
        isLessThan: today ?? CalendarDay.key(CalendarDay.today()),
      );
    }
    return query
        .orderBy('dueDate')
        .limit(limit)
        .snapshots()
        .transform(_results(_rows));
  }

  @override
  Stream<AppResult<List<TransactionRow>>> recentTransactions(
    String businessId, {
    int limit = 10,
  }) => _refs
      .transactions(businessId)
      .orderBy('dateTs', descending: true)
      .limit(limit)
      .snapshots()
      .transform(_results(_rows));

  @override
  Future<AppResult<ReportLabels>> labels(String businessId) =>
      AppResult.guard(() async {
        final [categories, projects] = await Future.wait([
          _refs.categories(businessId).get(),
          _refs.projects(businessId).get(),
        ]);
        Map<String, String> names(QuerySnapshot<JsonMap> snapshot) => {
          for (final doc in snapshot.docs)
            if (doc.data()['name'] case final String name) doc.id: name,
        };
        return ReportLabels(
          categories: names(categories),
          projects: names(projects),
        );
      });

  static List<TransactionRow> _rows(QuerySnapshot<JsonMap> snapshot) => [
    for (final doc in snapshot.docs) TransactionRow.fromMap(doc.id, doc.data()),
  ];

  static StreamTransformer<S, AppResult<T>> _results<S, T>(
    T Function(S source) convert,
  ) => StreamTransformer.fromHandlers(
    handleData: (source, sink) {
      try {
        sink.add(Success(convert(source)));
      } catch (error) {
        sink.add(Failure(AppException.from(error)));
      }
    },
    handleError: (error, _, sink) =>
        sink.add(Failure(AppException.from(error))),
  );
}
