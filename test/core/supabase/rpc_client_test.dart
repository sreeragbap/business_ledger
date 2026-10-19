import 'dart:io';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/fake_backend.dart';
import '../sync/sync_fakes.dart';

void main() {
  group('names and parameters (supabase/README.md, RPCs)', () {
    test('every callable maps to its RPC', () {
      expect(RpcClient.functions, {
        'createBusiness': 'create_business',
        'addMember': 'add_member',
        'updateMemberRole': 'update_member_role',
        'removeMember': 'remove_member',
        'deleteCategory': 'delete_category',
        'confirmTransaction': 'confirm_transaction',
        'editConfirmedTransaction': 'edit_confirmed_transaction',
        'cancelTransaction': 'cancel_transaction',
        'recordSettlement': 'record_settlement',
        'issueDocument': 'issue_document',
      });
      expect(() => RpcClient.functionFor('nope'), throwsArgumentError);
    });

    test('payload keys become p_ snake_case; nested JSON keeps camelCase; '
        'nulls are left out', () {
      expect(
        RpcClient.paramsFor({
          'businessId': 'b1',
          'transactionId': 't1',
          'requestId': 'r123456789',
          'expectedVersion': 3,
          'changes': {'dueDate': null, 'lineItems': <Object?>[]},
          'settleMethod': null,
        }),
        {
          'p_business_id': 'b1',
          'p_transaction_id': 't1',
          'p_request_id': 'r123456789',
          'p_expected_version': 3,
          'p_changes': {'dueDate': null, 'lineItems': <Object?>[]},
        },
      );
    });

    test('the create-business and member payloads', () {
      expect(
        RpcClient.paramsFor({
          'requestId': 'r1234567',
          'name': 'Shop',
          'currencyCode': 'INR',
          'timezone': 'Asia/Kolkata',
          'template': 'retail',
        }).keys,
        [
          'p_request_id',
          'p_name',
          'p_currency_code',
          'p_timezone',
          'p_template',
        ],
      );
      expect(
        RpcClient.paramsFor({'businessId': 'b', 'uid': 'u', 'role': 'admin'}),
        {'p_business_id': 'b', 'p_uid': 'u', 'p_role': 'admin'},
      );
      expect(
        RpcClient.paramsFor({
          'businessId': 'b',
          'transactionId': 't',
          'type': 'receipt',
          'requestId': 'r1234567',
          'settlementId': 's1',
        }).keys,
        [
          'p_business_id',
          'p_transaction_id',
          'p_type',
          'p_request_id',
          'p_settlement_id',
        ],
      );
    });
  });

  group('call', () {
    late FakeRemoteRpc remote;
    late FakeConnectivityService device;
    late FakeIdentity identity;
    late SyncSettings settings;
    late RpcClient client;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      remote = FakeRemoteRpc();
      device = FakeConnectivityService();
      identity = FakeIdentity();
      settings = SyncSettings(await SharedPreferences.getInstance());
      client = RpcClient(
        remote,
        CloudAvailability(device, settings, identity),
      );
    });

    test('sends the mapped call and returns the result map', () async {
      remote.answer('delete_category', () => {'categoryId': 'c1'});
      final result = await client.call('deleteCategory', {
        'businessId': 'b1',
        'categoryId': 'c1',
      });
      expect(result.dataOrNull, {'categoryId': 'c1'});
      expect(remote.calls.single.$1, 'delete_category');
      expect(remote.calls.single.$2, {
        'p_business_id': 'b1',
        'p_category_id': 'c1',
      });
    });

    test('refused up front offline, with sync off, or signed out', () async {
      device.isOnline = false;
      expect(
        (await client.call('deleteCategory', {})).errorOrNull,
        const AppException.offline(),
      );
      device.isOnline = true;
      await settings.setEnabled(value: false);
      expect(
        (await client.call('deleteCategory', {})).errorOrNull?.message,
        AppException.syncOffMessage,
      );
      await settings.setEnabled(value: true);
      identity.current = null;
      expect(
        (await client.call('deleteCategory', {})).errorOrNull?.kind,
        AppErrorKind.unauthenticated,
      );
      expect(remote.calls, isEmpty);
    });

    test('the queue and engine skip the up-front check', () async {
      device.isOnline = false;
      await client.call('deleteCategory', {}, requiresOnline: false);
      expect(remote.calls, hasLength(1));
    });

    test('a refusal comes back as the contract says', () async {
      remote.answer(
        'remove_member',
        () => throw const PostgrestException(
          message: 'Transfer ownership before the owner leaves.',
          code: 'PT412',
          details: '{"code":"failed-precondition","reason":"role"}',
        ),
      );
      final result = await client.call('removeMember', {
        'businessId': 'b1',
        'uid': 'u1',
      });
      expect(result.errorOrNull?.kind, AppErrorKind.permissionDenied);
      expect(
        result.errorOrNull?.message,
        'Transfer ownership before the owner leaves.',
      );
    });

    test('no network is offline', () async {
      remote.answer('add_member', () => throw const SocketException('down'));
      final result = await client.call('addMember', {});
      expect(result.errorOrNull?.isOffline, isTrue);
    });
  });
}
