import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/logic/members_cubit/members_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who is in the business and what they can do. Admins add members and
/// change roles (only the owner manages admins), the owner can hand over
/// ownership, and anyone but the owner can leave. Actions a role cannot
/// perform are not shown; the functions enforce the same rules.
@RoutePage()
class MembersScreen extends StatelessWidget implements AutoRouteWrapper {
  const MembersScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final businessId = context.read<BusinessScopeCubit>().state.businessId;
    return BlocProvider<MembersCubit>(
      create: (_) {
        final cubit = getIt<MembersCubit>();
        if (businessId != null) unawaited(cubit.watch(businessId));
        return cubit;
      },
      child: this,
    );
  }

  Future<void> _onAction(BuildContext context, MembersState state) async {
    final status = state.actionStatus;
    if (status.isFailure && state.action != MemberAction.add) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
    }
    if (!status.isSuccess) return;
    if (state.action == MemberAction.leave) {
      // The home shell sees the scope empty and opens the picker, which
      // shows this message.
      final scope = context.read<BusinessScopeCubit>();
      final name = scope.state.business?.name ?? 'the business';
      await scope.clear(message: 'You left $name.');
      return;
    }
    if (context.mounted) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select<BusinessScopeCubit, Member?>(
      (cubit) => cubit.state.member,
    );
    final role = me?.role ?? Role.viewer;
    return BlocListener<MembersCubit, MembersState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: (context, state) => unawaited(_onAction(context, state)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Members')),
        floatingActionButton: role.canManageMembers
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_showAddMember(context, role)),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add member'),
              )
            : null,
        body: BlocBuilder<MembersCubit, MembersState>(
          builder: (context, state) => AppAsyncView<List<Member>>(
            status: state.loadStatus,
            data: state.members,
            loading: const AppListSkeleton(rows: 4),
            builder: (context, members) => ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal.w,
                AppSpacing.sm.h,
                AppSpacing.screenHorizontal.w,
                96.h,
              ),
              children: [
                for (final member in members) ...[
                  _MemberTile(
                    member: member,
                    isMe: member.uid == me?.uid,
                    myRole: role,
                    busy: state.isBusy(member.uid),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                ],
                if (me != null && !role.isOwner) ...[
                  SizedBox(height: AppSpacing.xxl.h),
                  AppButton.secondary(
                    label: 'Leave business',
                    icon: Icons.logout_rounded,
                    destructive: true,
                    isLoading: state.isBusy(me.uid),
                    onPressed: () => unawaited(_confirmLeave(context, me)),
                  ),
                ],
                if (role.isOwner) ...[
                  SizedBox(height: AppSpacing.xxl.h),
                  Text(
                    'To leave, first make someone else the owner.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, Member me) async {
    final cubit = context.read<MembersCubit>();
    final business = context.read<BusinessScopeCubit>().state.business;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Leave ${business?.name ?? 'this business'}?',
      message:
          'You lose access straight away. An admin can add you again '
          'later.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (confirmed) await cubit.leave(me.uid);
  }

  Future<void> _showAddMember(BuildContext context, Role myRole) {
    final cubit = context.read<MembersCubit>();
    return showAppBottomSheet<void>(
      context: context,
      title: 'Add a member',
      child: BlocProvider<MembersCubit>.value(
        value: cubit,
        child: _AddMemberForm(roles: myRole.assignableRoles),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.myRole,
    required this.busy,
  });

  final Member member;
  final bool isMe;
  final Role myRole;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canManage = !isMe && myRole.canManage(member.role);
    final canTransfer = !isMe && myRole.canTransferOwnership;
    final photo = member.photoUrl;
    return AppCard(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.md.h,
        AppSpacing.xs.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.surfaceHigh,
            foregroundImage: photo.isEmpty ? null : NetworkImage(photo),
            child: Text(member.initials, style: textTheme.labelMedium),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${member.name} (you)' : member.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.email.isNotEmpty && member.email != member.name)
                  Text(
                    member.email,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          RoleChip(role: member.role),
          SizedBox(
            width: 48.w,
            child: busy
                ? Center(
                    child: SizedBox.square(
                      dimension: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (canManage || canTransfer)
                ? PopupMenuButton<_MemberMenu>(
                    tooltip: 'Member actions',
                    onSelected: (choice) => unawaited(_onMenu(context, choice)),
                    itemBuilder: (_) => [
                      if (canManage)
                        const PopupMenuItem(
                          value: _MemberMenu.changeRole,
                          child: Text('Change role'),
                        ),
                      if (canTransfer)
                        const PopupMenuItem(
                          value: _MemberMenu.transfer,
                          child: Text('Make owner'),
                        ),
                      if (canManage)
                        const PopupMenuItem(
                          value: _MemberMenu.remove,
                          child: Text(
                            'Remove',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, _MemberMenu choice) async {
    final cubit = context.read<MembersCubit>();
    switch (choice) {
      case _MemberMenu.changeRole:
        final role = await showAppBottomSheet<Role>(
          context: context,
          title: 'Role for ${member.name}',
          child: _RolePicker(
            roles: myRole.assignableRoles,
            selected: member.role,
          ),
        );
        if (role != null && role != member.role) {
          await cubit.changeRole(member, role);
        }
      case _MemberMenu.transfer:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: 'Make ${member.name} the owner?',
          message:
              'They get full control, including archiving the business. '
              'You become an admin, and only they can make you owner again.',
          confirmLabel: 'Transfer ownership',
          destructive: true,
        );
        if (confirmed) await cubit.transferOwnership(member);
      case _MemberMenu.remove:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: 'Remove ${member.name}?',
          message: 'They lose access to this business straight away.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (confirmed) await cubit.remove(member);
    }
  }
}

enum _MemberMenu { changeRole, transfer, remove }

/// Picks one of [roles]; pops with the choice.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.roles, this.selected});

  final List<Role> roles;
  final Role? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final role in roles)
          _RoleOption(
            role: role,
            selected: role == selected,
            onTap: () => Navigator.of(context).pop(role),
          ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final Role role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? AppColors.accent : null,
      ),
      title: Text(role.label),
      subtitle: Text(role.description),
    );
  }
}

class _AddMemberForm extends StatefulWidget {
  const _AddMemberForm({required this.roles});

  final List<Role> roles;

  @override
  State<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<_AddMemberForm> {
  final _email = TextEditingController();
  late Role _role = widget.roles.contains(Role.editor)
      ? Role.editor
      : widget.roles.last;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MembersCubit, MembersState>(
      listenWhen: (p, c) =>
          c.action == MemberAction.add && p.actionStatus != c.actionStatus,
      listener: (context, state) {
        if (state.actionStatus.isSuccess) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final adding = state.action == MemberAction.add;
        final status = adding ? state.actionStatus : null;
        final loading = status?.isLoading ?? false;
        final error = status != null && status.isFailure
            ? status.errorFor('email') ?? status.message
            : null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _email,
              label: 'Email',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autofocus: true,
              enabled: !loading,
              errorText: error,
              helperText:
                  'They must have signed in to the app once with this email.',
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text('Role', style: Theme.of(context).textTheme.labelMedium),
            for (final role in widget.roles)
              _RoleOption(
                role: role,
                selected: role == _role,
                onTap: () {
                  if (!loading) setState(() => _role = role);
                },
              ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'Add member',
              isLoading: loading,
              onPressed: () => unawaited(
                context.read<MembersCubit>().add(
                  email: _email.text,
                  role: _role,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
