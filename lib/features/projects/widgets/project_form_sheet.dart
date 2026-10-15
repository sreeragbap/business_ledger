import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/logic/projects_cubit/projects_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the project form. Resolves the edited project (empty id for a new
/// one) or `null` when dismissed.
Future<Project?> showProjectForm(BuildContext context, {Project? project}) =>
    showAppBottomSheet<Project>(
      context: context,
      title: project == null ? 'New project' : 'Edit project',
      child: ProjectForm(project: project),
    );

class ProjectForm extends StatefulWidget {
  const ProjectForm({this.project, super.key});

  final Project? project;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  late final Project _initial =
      widget.project ?? const Project(id: '', name: '');
  late final _name = TextEditingController(text: _initial.name);
  late final _code = TextEditingController(text: _initial.code);
  late final _description = TextEditingController(
    text: _initial.description,
  );
  Map<String, List<String>> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final project = _initial.copyWith(
      name: _name.text.trim(),
      code: _code.text.trim(),
      description: _description.text.trim(),
    );
    final errors = ProjectsCubit.validate(project);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.of(context).pop(project);
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
          hint: 'e.g. Villa extension, Kakkanad',
          autofocus: widget.project == null,
          textCapitalization: TextCapitalization.sentences,
          maxLength: Project.maxNameLength,
          errorText: _errors['name']?.first,
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: _code,
          label: 'Code (optional)',
          hint: 'e.g. SITE-12',
          textCapitalization: TextCapitalization.characters,
          maxLength: Project.maxCodeLength,
          errorText: _errors['code']?.first,
        ),
        SizedBox(height: AppSpacing.lg.h),
        AppTextField(
          controller: _description,
          label: 'Notes (optional)',
          maxLines: 3,
          minLines: 1,
          maxLength: 300,
        ),
        SizedBox(height: AppSpacing.xxl.h),
        AppButton(
          label: widget.project == null ? 'Add project' : 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}
