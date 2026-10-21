import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/logic/parties_cubit/parties_cubit.dart';
import 'package:business_ledger/features/parties/widgets/party_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Customers and suppliers, searchable, filterable by kind.
@RoutePage()
class PartiesScreen extends StatelessWidget implements AutoRouteWrapper {
  const PartiesScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final businessId = context.read<BusinessScopeCubit>().state.businessId;
    return BlocProvider<PartiesCubit>(
      create: (_) {
        final cubit = getIt<PartiesCubit>();
        if (businessId != null) unawaited(cubit.watch(businessId));
        return cubit;
      },
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<BusinessScopeCubit, Role>(
      (cubit) => cubit.state.role,
    );
    final canEdit = role.canEditConfig;
    return BlocListener<PartiesCubit, PartiesState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: (context, state) {
        final status = state.actionStatus;
        if (status.isFailure) {
          showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
        } else if (status.isSuccess) {
          showAppSnackBar(
            context,
            status.message,
            kind: AppSnackBarKind.success,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customers & suppliers'),
          actions: [
            BlocBuilder<PartiesCubit, PartiesState>(
              buildWhen: (p, c) =>
                  p.showArchived != c.showArchived ||
                  p.archivedCount != c.archivedCount,
              builder: (context, state) =>
                  state.archivedCount == 0 && !state.showArchived
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: state.showArchived
                          ? 'Show active'
                          : 'Show archived',
                      icon: Icon(
                        state.showArchived
                            ? Icons.inventory_2_rounded
                            : Icons.inventory_2_outlined,
                      ),
                      onPressed: context.read<PartiesCubit>().toggleArchived,
                    ),
            ),
          ],
        ),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_edit(context, null)),
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Add'),
              )
            : null,
        body: Column(
          children: [
            const _Filters(),
            Expanded(
              child: BlocBuilder<PartiesCubit, PartiesState>(
                builder: (context, state) => AppAsyncView<List<Party>>(
                  status: state.loadStatus,
                  data: state.visible,
                  isEmpty: (items) => items.isEmpty,
                  loading: const AppListSkeleton(),
                  empty: _empty(context, state, canEdit),
                  builder: (context, parties) => ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal.w,
                      AppSpacing.sm.h,
                      AppSpacing.screenHorizontal.w,
                      96.h,
                    ),
                    itemCount: parties.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSpacing.sm.h),
                    itemBuilder: (context, index) =>
                        _PartyTile(party: parties[index], canEdit: canEdit),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, PartiesState state, bool canEdit) {
    if (state.isFiltering) {
      return const AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try another name, number or filter.',
      );
    }
    if (state.showArchived) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Nothing archived',
      );
    }
    return AppEmptyState(
      icon: Icons.people_outline_rounded,
      title: 'No customers or suppliers yet',
      message:
          'Add the people you sell to and buy from to track who owes '
          'what.',
      action: canEdit
          ? AppButton(
              label: 'Add one',
              icon: Icons.add_rounded,
              expand: false,
              onPressed: () => unawaited(_edit(context, null)),
            )
          : null,
    );
  }
}

Future<void> _edit(BuildContext context, Party? party) async {
  final cubit = context.read<PartiesCubit>();
  final result = await showPartyForm(
    context,
    party: party,
    initialKind: cubit.state.kindFilter ?? PartyKind.customer,
  );
  if (result != null) await cubit.save(result);
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartiesCubit>();
    final kind = context.select<PartiesCubit, PartyKind?>(
      (cubit) => cubit.state.kindFilter,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal.w,
        AppSpacing.xs.h,
        AppSpacing.screenHorizontal.w,
        AppSpacing.sm.h,
      ),
      child: Column(
        children: [
          AppTextField(
            hint: 'Search name, phone or email',
            prefixIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: cubit.search,
          ),
          SizedBox(height: AppSpacing.sm.h),
          SizedBox(
            height: 40.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in <PartyKind?>[
                  null,
                  PartyKind.customer,
                  PartyKind.supplier,
                  PartyKind.both,
                ]) ...[
                  ChoiceChip(
                    label: Text(option?.pluralLabel ?? 'All'),
                    selected: option == kind,
                    onSelected: (_) => cubit.filterKind(option),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyTile extends StatelessWidget {
  const _PartyTile({required this.party, required this.canEdit});

  final Party party;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final contact = [
      party.kind.label,
      if (party.phone.isNotEmpty) party.phone,
      if (party.email.isNotEmpty) party.email,
    ].join(' · ');
    return AppCard(
      onTap: canEdit ? () => unawaited(_edit(context, party)) : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.md.h,
        AppSpacing.xs.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: context.colors.surfaceHigh,
            child: Icon(party.kind.icon, size: 18.r),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  contact,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<bool>(
              tooltip: 'Actions',
              onSelected: (archive) => unawaited(
                context.read<PartiesCubit>().setArchived(
                  party,
                  archived: archive,
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: !party.archived,
                  child: Text(party.archived ? 'Restore' : 'Archive'),
                ),
              ],
            )
          else
            SizedBox(width: AppSpacing.md.w),
        ],
      ),
    );
  }
}
