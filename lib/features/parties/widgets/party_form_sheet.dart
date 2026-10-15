import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/logic/parties_cubit/parties_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the party form. Resolves the edited party (empty id for a new one)
/// or `null` when dismissed. [initialKind] presets a new party's kind (a
/// purchase form adding a supplier, say).
Future<Party?> showPartyForm(
  BuildContext context, {
  Party? party,
  PartyKind initialKind = PartyKind.customer,
}) => showAppBottomSheet<Party>(
  context: context,
  title: party == null ? 'New ${initialKind.label.toLowerCase()}' : 'Edit',
  child: PartyForm(party: party, initialKind: initialKind),
);

class PartyForm extends StatefulWidget {
  const PartyForm({
    this.party,
    this.initialKind = PartyKind.customer,
    super.key,
  });

  final Party? party;
  final PartyKind initialKind;

  @override
  State<PartyForm> createState() => _PartyFormState();
}

class _PartyFormState extends State<PartyForm> {
  late final Party _initial =
      widget.party ?? Party(id: '', name: '', kind: widget.initialKind);
  late final _name = TextEditingController(text: _initial.name);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _email = TextEditingController(text: _initial.email);
  late final _address = TextEditingController(text: _initial.address);
  late PartyKind _kind = _initial.kind;
  Map<String, List<String>> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    final party = _initial.copyWith(
      name: _name.text.trim(),
      kind: _kind,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    final errors = PartiesCubit.validate(party);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.of(context).pop(party);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _name,
          label: 'Name',
          hint: 'Person or company',
          autofocus: widget.party == null,
          textCapitalization: TextCapitalization.words,
          maxLength: Party.maxNameLength,
          errorText: _errors['name']?.first,
        ),
        SizedBox(height: AppSpacing.lg.h),
        SegmentedButton<PartyKind>(
          segments: [
            for (final kind in PartyKind.values)
              ButtonSegment(
                value: kind,
                label: Text(kind == PartyKind.both ? 'Both' : kind.label),
                icon: Icon(kind.icon, size: 18.r),
              ),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _kind = selection.first),
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: _phone,
          label: 'Phone (optional)',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          maxLength: 30,
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: _email,
          label: 'Email (optional)',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          maxLength: 120,
          errorText: _errors['email']?.first,
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: _address,
          label: 'Address (optional)',
          maxLines: 3,
          minLines: 1,
          maxLength: 300,
        ),
        SizedBox(height: AppSpacing.xxl.h),
        AppButton(
          label: widget.party == null ? 'Add' : 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}
