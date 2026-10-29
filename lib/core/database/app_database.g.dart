// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastBusinessIdMeta = const VerificationMeta(
    'lastBusinessId',
  );
  @override
  late final GeneratedColumn<String> lastBusinessId = GeneratedColumn<String>(
    'last_business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    displayName,
    photoUrl,
    lastBusinessId,
    createdAt,
    updatedAt,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('last_business_id')) {
      context.handle(
        _lastBusinessIdMeta,
        lastBusinessId.isAcceptableOrUnknown(
          data['last_business_id']!,
          _lastBusinessIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      )!,
      lastBusinessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_business_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? lastBusinessId;
  final String? createdAt;
  final String? updatedAt;
  final bool localPending;
  const ProfileRow({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.lastBusinessId,
    this.createdAt,
    this.updatedAt,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['photo_url'] = Variable<String>(photoUrl);
    if (!nullToAbsent || lastBusinessId != null) {
      map['last_business_id'] = Variable<String>(lastBusinessId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      email: Value(email),
      displayName: Value(displayName),
      photoUrl: Value(photoUrl),
      lastBusinessId: lastBusinessId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBusinessId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      localPending: Value(localPending),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['display_name']),
      photoUrl: serializer.fromJson<String>(json['photo_url']),
      lastBusinessId: serializer.fromJson<String?>(json['last_business_id']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'display_name': serializer.toJson<String>(displayName),
      'photo_url': serializer.toJson<String>(photoUrl),
      'last_business_id': serializer.toJson<String?>(lastBusinessId),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  ProfileRow copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    Value<String?> lastBusinessId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    bool? localPending,
  }) => ProfileRow(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    lastBusinessId: lastBusinessId.present
        ? lastBusinessId.value
        : this.lastBusinessId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    localPending: localPending ?? this.localPending,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      lastBusinessId: data.lastBusinessId.present
          ? data.lastBusinessId.value
          : this.lastBusinessId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('lastBusinessId: $lastBusinessId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    photoUrl,
    lastBusinessId,
    createdAt,
    updatedAt,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.photoUrl == this.photoUrl &&
          other.lastBusinessId == this.lastBusinessId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.localPending == this.localPending);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> photoUrl;
  final Value<String?> lastBusinessId;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<bool> localPending;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.lastBusinessId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.lastBusinessId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? photoUrl,
    Expression<String>? lastBusinessId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (lastBusinessId != null) 'last_business_id': lastBusinessId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? displayName,
    Value<String>? photoUrl,
    Value<String?>? lastBusinessId,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastBusinessId: lastBusinessId ?? this.lastBusinessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (lastBusinessId.present) {
      map['last_business_id'] = Variable<String>(lastBusinessId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('lastBusinessId: $lastBusinessId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessesTable extends Businesses
    with TableInfo<$BusinessesTable, BusinessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyDecimalsMeta = const VerificationMeta(
    'currencyDecimals',
  );
  @override
  late final GeneratedColumn<int> currencyDecimals = GeneratedColumn<int>(
    'currency_decimals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _currencySymbolMeta = const VerificationMeta(
    'currencySymbol',
  );
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
    'currency_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _templateMeta = const VerificationMeta(
    'template',
  );
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, dynamic>>($BusinessesTable.$convertersettings);
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    currencyCode,
    currencyDecimals,
    currencySymbol,
    timezone,
    template,
    ownerId,
    settings,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'businesses';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('currency_decimals')) {
      context.handle(
        _currencyDecimalsMeta,
        currencyDecimals.isAcceptableOrUnknown(
          data['currency_decimals']!,
          _currencyDecimalsMeta,
        ),
      );
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
        _currencySymbolMeta,
        currencySymbol.isAcceptableOrUnknown(
          data['currency_symbol']!,
          _currencySymbolMeta,
        ),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('template')) {
      context.handle(
        _templateMeta,
        template.isAcceptableOrUnknown(data['template']!, _templateMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      currencyDecimals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}currency_decimals'],
      )!,
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      template: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      settings: $BusinessesTable.$convertersettings.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}settings'],
        )!,
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $BusinessesTable createAlias(String alias) {
    return $BusinessesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $convertersettings = const JsonMapConverter();
}

class BusinessRow extends DataClass implements Insertable<BusinessRow> {
  final String id;
  final String name;
  final String description;
  final String currencyCode;
  final int currencyDecimals;
  final String currencySymbol;
  final String timezone;
  final String template;
  final String ownerId;
  final Map<String, dynamic> settings;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final int seq;
  final bool localPending;
  const BusinessRow({
    required this.id,
    required this.name,
    required this.description,
    required this.currencyCode,
    required this.currencyDecimals,
    required this.currencySymbol,
    required this.timezone,
    required this.template,
    required this.ownerId,
    required this.settings,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['currency_code'] = Variable<String>(currencyCode);
    map['currency_decimals'] = Variable<int>(currencyDecimals);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    map['timezone'] = Variable<String>(timezone);
    map['template'] = Variable<String>(template);
    map['owner_id'] = Variable<String>(ownerId);
    {
      map['settings'] = Variable<String>(
        $BusinessesTable.$convertersettings.toSql(settings),
      );
    }
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  BusinessesCompanion toCompanion(bool nullToAbsent) {
    return BusinessesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      currencyCode: Value(currencyCode),
      currencyDecimals: Value(currencyDecimals),
      currencySymbol: Value(currencySymbol),
      timezone: Value(timezone),
      template: Value(template),
      ownerId: Value(ownerId),
      settings: Value(settings),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory BusinessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      currencyCode: serializer.fromJson<String>(json['currency_code']),
      currencyDecimals: serializer.fromJson<int>(json['currency_decimals']),
      currencySymbol: serializer.fromJson<String>(json['currency_symbol']),
      timezone: serializer.fromJson<String>(json['timezone']),
      template: serializer.fromJson<String>(json['template']),
      ownerId: serializer.fromJson<String>(json['owner_id']),
      settings: $BusinessesTable.$convertersettings.fromJson(
        serializer.fromJson<Object?>(json['settings']),
      ),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'currency_code': serializer.toJson<String>(currencyCode),
      'currency_decimals': serializer.toJson<int>(currencyDecimals),
      'currency_symbol': serializer.toJson<String>(currencySymbol),
      'timezone': serializer.toJson<String>(timezone),
      'template': serializer.toJson<String>(template),
      'owner_id': serializer.toJson<String>(ownerId),
      'settings': serializer.toJson<Object?>(
        $BusinessesTable.$convertersettings.toJson(settings),
      ),
      'archived': serializer.toJson<bool>(archived),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  BusinessRow copyWith({
    String? id,
    String? name,
    String? description,
    String? currencyCode,
    int? currencyDecimals,
    String? currencySymbol,
    String? timezone,
    String? template,
    String? ownerId,
    Map<String, dynamic>? settings,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => BusinessRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    currencyCode: currencyCode ?? this.currencyCode,
    currencyDecimals: currencyDecimals ?? this.currencyDecimals,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    timezone: timezone ?? this.timezone,
    template: template ?? this.template,
    ownerId: ownerId ?? this.ownerId,
    settings: settings ?? this.settings,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  BusinessRow copyWithCompanion(BusinessesCompanion data) {
    return BusinessRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      currencyDecimals: data.currencyDecimals.present
          ? data.currencyDecimals.value
          : this.currencyDecimals,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      template: data.template.present ? data.template.value : this.template,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      settings: data.settings.present ? data.settings.value : this.settings,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDecimals: $currencyDecimals, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('timezone: $timezone, ')
          ..write('template: $template, ')
          ..write('ownerId: $ownerId, ')
          ..write('settings: $settings, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    currencyCode,
    currencyDecimals,
    currencySymbol,
    timezone,
    template,
    ownerId,
    settings,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.currencyCode == this.currencyCode &&
          other.currencyDecimals == this.currencyDecimals &&
          other.currencySymbol == this.currencySymbol &&
          other.timezone == this.timezone &&
          other.template == this.template &&
          other.ownerId == this.ownerId &&
          other.settings == this.settings &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class BusinessesCompanion extends UpdateCompanion<BusinessRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> currencyCode;
  final Value<int> currencyDecimals;
  final Value<String> currencySymbol;
  final Value<String> timezone;
  final Value<String> template;
  final Value<String> ownerId;
  final Value<Map<String, dynamic>> settings;
  final Value<bool> archived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const BusinessesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyDecimals = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.timezone = const Value.absent(),
    this.template = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.settings = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyDecimals = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.timezone = const Value.absent(),
    this.template = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.settings = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BusinessRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? currencyCode,
    Expression<int>? currencyDecimals,
    Expression<String>? currencySymbol,
    Expression<String>? timezone,
    Expression<String>? template,
    Expression<String>? ownerId,
    Expression<String>? settings,
    Expression<bool>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencyDecimals != null) 'currency_decimals': currencyDecimals,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (timezone != null) 'timezone': timezone,
      if (template != null) 'template': template,
      if (ownerId != null) 'owner_id': ownerId,
      if (settings != null) 'settings': settings,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? currencyCode,
    Value<int>? currencyDecimals,
    Value<String>? currencySymbol,
    Value<String>? timezone,
    Value<String>? template,
    Value<String>? ownerId,
    Value<Map<String, dynamic>>? settings,
    Value<bool>? archived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return BusinessesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyDecimals: currencyDecimals ?? this.currencyDecimals,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      timezone: timezone ?? this.timezone,
      template: template ?? this.template,
      ownerId: ownerId ?? this.ownerId,
      settings: settings ?? this.settings,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (currencyDecimals.present) {
      map['currency_decimals'] = Variable<int>(currencyDecimals.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(
        $BusinessesTable.$convertersettings.toSql(settings.value),
      );
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDecimals: $currencyDecimals, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('timezone: $timezone, ')
          ..write('template: $template, ')
          ..write('ownerId: $ownerId, ')
          ..write('settings: $settings, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('viewer'),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addedByMeta = const VerificationMeta(
    'addedBy',
  );
  @override
  late final GeneratedColumn<String> addedBy = GeneratedColumn<String>(
    'added_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<String> addedAt = GeneratedColumn<String>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    userId,
    role,
    email,
    displayName,
    photoUrl,
    addedBy,
    addedAt,
    updatedAt,
    deletedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('added_by')) {
      context.handle(
        _addedByMeta,
        addedBy.isAcceptableOrUnknown(data['added_by']!, _addedByMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, userId};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      )!,
      addedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_by'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String businessId;
  final String userId;
  final String role;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? addedBy;
  final String? addedAt;
  final String? updatedAt;
  final String? deletedAt;
  final int seq;
  const MemberRow({
    required this.businessId,
    required this.userId,
    required this.role,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.addedBy,
    this.addedAt,
    this.updatedAt,
    this.deletedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['photo_url'] = Variable<String>(photoUrl);
    if (!nullToAbsent || addedBy != null) {
      map['added_by'] = Variable<String>(addedBy);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<String>(addedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['seq'] = Variable<int>(seq);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      businessId: Value(businessId),
      userId: Value(userId),
      role: Value(role),
      email: Value(email),
      displayName: Value(displayName),
      photoUrl: Value(photoUrl),
      addedBy: addedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(addedBy),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      seq: Value(seq),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      businessId: serializer.fromJson<String>(json['business_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      role: serializer.fromJson<String>(json['role']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['display_name']),
      photoUrl: serializer.fromJson<String>(json['photo_url']),
      addedBy: serializer.fromJson<String?>(json['added_by']),
      addedAt: serializer.fromJson<String?>(json['added_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      deletedAt: serializer.fromJson<String?>(json['deleted_at']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'user_id': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'email': serializer.toJson<String>(email),
      'display_name': serializer.toJson<String>(displayName),
      'photo_url': serializer.toJson<String>(photoUrl),
      'added_by': serializer.toJson<String?>(addedBy),
      'added_at': serializer.toJson<String?>(addedAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'deleted_at': serializer.toJson<String?>(deletedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  MemberRow copyWith({
    String? businessId,
    String? userId,
    String? role,
    String? email,
    String? displayName,
    String? photoUrl,
    Value<String?> addedBy = const Value.absent(),
    Value<String?> addedAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    int? seq,
  }) => MemberRow(
    businessId: businessId ?? this.businessId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    addedBy: addedBy.present ? addedBy.value : this.addedBy,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    seq: seq ?? this.seq,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      addedBy: data.addedBy.present ? data.addedBy.value : this.addedBy,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('addedBy: $addedBy, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    userId,
    role,
    email,
    displayName,
    photoUrl,
    addedBy,
    addedAt,
    updatedAt,
    deletedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.businessId == this.businessId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.photoUrl == this.photoUrl &&
          other.addedBy == this.addedBy &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.seq == this.seq);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> businessId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> photoUrl;
  final Value<String?> addedBy;
  final Value<String?> addedAt;
  final Value<String?> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> seq;
  final Value<int> rowid;
  const MembersCompanion({
    this.businessId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String businessId,
    required String userId,
    this.role = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       userId = Value(userId);
  static Insertable<MemberRow> custom({
    Expression<String>? businessId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? photoUrl,
    Expression<String>? addedBy,
    Expression<String>? addedAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (addedBy != null) 'added_by': addedBy,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? businessId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? email,
    Value<String>? displayName,
    Value<String>? photoUrl,
    Value<String?>? addedBy,
    Value<String?>? addedAt,
    Value<String?>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (addedBy.present) {
      map['added_by'] = Variable<String>(addedBy.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<String>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('addedBy: $addedBy, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
    'colour',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> fieldIds =
      GeneratedColumn<String>(
        'field_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<dynamic>>($CategoriesTable.$converterfieldIds);
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    kind,
    icon,
    colour,
    fieldIds,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    deletedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colour'],
      )!,
      fieldIds: $CategoriesTable.$converterfieldIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}field_ids'],
        )!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<dynamic>, String, Object?> $converterfieldIds =
      const JsonListConverter();
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String businessId;
  final String name;
  final String kind;
  final String icon;
  final String colour;
  final List<dynamic> fieldIds;
  final int sortOrder;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int seq;
  final bool localPending;
  const CategoryRow({
    required this.id,
    required this.businessId,
    required this.name,
    required this.kind,
    required this.icon,
    required this.colour,
    required this.fieldIds,
    required this.sortOrder,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['icon'] = Variable<String>(icon);
    map['colour'] = Variable<String>(colour);
    {
      map['field_ids'] = Variable<String>(
        $CategoriesTable.$converterfieldIds.toSql(fieldIds),
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      kind: Value(kind),
      icon: Value(icon),
      colour: Value(colour),
      fieldIds: Value(fieldIds),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      icon: serializer.fromJson<String>(json['icon']),
      colour: serializer.fromJson<String>(json['colour']),
      fieldIds: $CategoriesTable.$converterfieldIds.fromJson(
        serializer.fromJson<Object?>(json['field_ids']),
      ),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      deletedAt: serializer.fromJson<String?>(json['deleted_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'icon': serializer.toJson<String>(icon),
      'colour': serializer.toJson<String>(colour),
      'field_ids': serializer.toJson<Object?>(
        $CategoriesTable.$converterfieldIds.toJson(fieldIds),
      ),
      'sort_order': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'deleted_at': serializer.toJson<String?>(deletedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? businessId,
    String? name,
    String? kind,
    String? icon,
    String? colour,
    List<dynamic>? fieldIds,
    int? sortOrder,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => CategoryRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon ?? this.icon,
    colour: colour ?? this.colour,
    fieldIds: fieldIds ?? this.fieldIds,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      icon: data.icon.present ? data.icon.value : this.icon,
      colour: data.colour.present ? data.colour.value : this.colour,
      fieldIds: data.fieldIds.present ? data.fieldIds.value : this.fieldIds,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('fieldIds: $fieldIds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    kind,
    icon,
    colour,
    fieldIds,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    deletedAt,
    seq,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.icon == this.icon &&
          other.colour == this.colour &&
          other.fieldIds == this.fieldIds &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> icon;
  final Value<String> colour;
  final Value<List<dynamic>> fieldIds;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.fieldIds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String businessId,
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.fieldIds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? icon,
    Expression<String>? colour,
    Expression<String>? fieldIds,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (icon != null) 'icon': icon,
      if (colour != null) 'colour': colour,
      if (fieldIds != null) 'field_ids': fieldIds,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? icon,
    Value<String>? colour,
    Value<List<dynamic>>? fieldIds,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      colour: colour ?? this.colour,
      fieldIds: fieldIds ?? this.fieldIds,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (fieldIds.present) {
      map['field_ids'] = Variable<String>(
        $CategoriesTable.$converterfieldIds.toSql(fieldIds.value),
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('fieldIds: $fieldIds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFieldsTable extends CustomFields
    with TableInfo<$CustomFieldsTable, CustomFieldRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> options =
      GeneratedColumn<String>(
        'options',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<dynamic>>($CustomFieldsTable.$converteroptions);
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    label,
    type,
    options,
    required,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFieldRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFieldRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFieldRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      options: $CustomFieldsTable.$converteroptions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}options'],
        )!,
      ),
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $CustomFieldsTable createAlias(String alias) {
    return $CustomFieldsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<dynamic>, String, Object?> $converteroptions =
      const JsonListConverter();
}

class CustomFieldRow extends DataClass implements Insertable<CustomFieldRow> {
  final String id;
  final String businessId;
  final String label;
  final String type;
  final List<dynamic> options;
  final bool required;
  final int sortOrder;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final int seq;
  final bool localPending;
  const CustomFieldRow({
    required this.id,
    required this.businessId,
    required this.label,
    required this.type,
    required this.options,
    required this.required,
    required this.sortOrder,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['label'] = Variable<String>(label);
    map['type'] = Variable<String>(type);
    {
      map['options'] = Variable<String>(
        $CustomFieldsTable.$converteroptions.toSql(options),
      );
    }
    map['required'] = Variable<bool>(required);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  CustomFieldsCompanion toCompanion(bool nullToAbsent) {
    return CustomFieldsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      label: Value(label),
      type: Value(type),
      options: Value(options),
      required: Value(required),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory CustomFieldRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFieldRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      label: serializer.fromJson<String>(json['label']),
      type: serializer.fromJson<String>(json['type']),
      options: $CustomFieldsTable.$converteroptions.fromJson(
        serializer.fromJson<Object?>(json['options']),
      ),
      required: serializer.fromJson<bool>(json['required']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'business_id': serializer.toJson<String>(businessId),
      'label': serializer.toJson<String>(label),
      'type': serializer.toJson<String>(type),
      'options': serializer.toJson<Object?>(
        $CustomFieldsTable.$converteroptions.toJson(options),
      ),
      'required': serializer.toJson<bool>(required),
      'sort_order': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  CustomFieldRow copyWith({
    String? id,
    String? businessId,
    String? label,
    String? type,
    List<dynamic>? options,
    bool? required,
    int? sortOrder,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => CustomFieldRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    label: label ?? this.label,
    type: type ?? this.type,
    options: options ?? this.options,
    required: required ?? this.required,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  CustomFieldRow copyWithCompanion(CustomFieldsCompanion data) {
    return CustomFieldRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      label: data.label.present ? data.label.value : this.label,
      type: data.type.present ? data.type.value : this.type,
      options: data.options.present ? data.options.value : this.options,
      required: data.required.present ? data.required.value : this.required,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('required: $required, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    label,
    type,
    options,
    required,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFieldRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.label == this.label &&
          other.type == this.type &&
          other.options == this.options &&
          other.required == this.required &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class CustomFieldsCompanion extends UpdateCompanion<CustomFieldRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> label;
  final Value<String> type;
  final Value<List<dynamic>> options;
  final Value<bool> required;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const CustomFieldsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.required = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomFieldsCompanion.insert({
    required String id,
    required String businessId,
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.required = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<CustomFieldRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? label,
    Expression<String>? type,
    Expression<String>? options,
    Expression<bool>? required,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (label != null) 'label': label,
      if (type != null) 'type': type,
      if (options != null) 'options': options,
      if (required != null) 'required': required,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? label,
    Value<String>? type,
    Value<List<dynamic>>? options,
    Value<bool>? required,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return CustomFieldsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? this.options,
      required: required ?? this.required,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(
        $CustomFieldsTable.$converteroptions.toSql(options.value),
      );
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('required: $required, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PartiesTable extends Parties with TableInfo<$PartiesTable, PartyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('customer'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    kind,
    phone,
    email,
    address,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parties';
  @override
  VerificationContext validateIntegrity(
    Insertable<PartyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PartyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PartyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $PartiesTable createAlias(String alias) {
    return $PartiesTable(attachedDatabase, alias);
  }
}

class PartyRow extends DataClass implements Insertable<PartyRow> {
  final String id;
  final String businessId;
  final String name;
  final String kind;
  final String phone;
  final String email;
  final String address;
  final int sortOrder;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final int seq;
  final bool localPending;
  const PartyRow({
    required this.id,
    required this.businessId,
    required this.name,
    required this.kind,
    required this.phone,
    required this.email,
    required this.address,
    required this.sortOrder,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['address'] = Variable<String>(address);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  PartiesCompanion toCompanion(bool nullToAbsent) {
    return PartiesCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      kind: Value(kind),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory PartyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PartyRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      address: serializer.fromJson<String>(json['address']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'address': serializer.toJson<String>(address),
      'sort_order': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  PartyRow copyWith({
    String? id,
    String? businessId,
    String? name,
    String? kind,
    String? phone,
    String? email,
    String? address,
    int? sortOrder,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => PartyRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  PartyRow copyWithCompanion(PartiesCompanion data) {
    return PartyRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PartyRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    kind,
    phone,
    email,
    address,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartyRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class PartiesCompanion extends UpdateCompanion<PartyRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> phone;
  final Value<String> email;
  final Value<String> address;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const PartiesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartiesCompanion.insert({
    required String id,
    required String businessId,
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<PartyRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartiesCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? phone,
    Value<String>? email,
    Value<String>? address,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return PartiesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartiesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    code,
    description,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final String id;
  final String businessId;
  final String name;
  final String code;
  final String description;
  final int sortOrder;
  final bool archived;
  final String? createdAt;
  final String? updatedAt;
  final int seq;
  final bool localPending;
  const ProjectRow({
    required this.id,
    required this.businessId,
    required this.name,
    required this.code,
    required this.description,
    required this.sortOrder,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['description'] = Variable<String>(description);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      code: Value(code),
      description: Value(description),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory ProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String>(description),
      'sort_order': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  ProjectRow copyWith({
    String? id,
    String? businessId,
    String? name,
    String? code,
    String? description,
    int? sortOrder,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => ProjectRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    code: code ?? this.code,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    code,
    description,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
    seq,
    localPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.code == this.code &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> code;
  final Value<String> description;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String businessId,
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<ProjectRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? code,
    Value<String>? description,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRowData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyIdMeta = const VerificationMeta(
    'partyId',
  );
  @override
  late final GeneratedColumn<String> partyId = GeneratedColumn<String>(
    'party_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptDateMeta = const VerificationMeta(
    'receiptDate',
  );
  @override
  late final GeneratedColumn<String> receiptDate = GeneratedColumn<String>(
    'receipt_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String> lineItems =
      GeneratedColumn<String>(
        'line_items',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<dynamic>>($TransactionsTable.$converterlineItems);
  static const VerificationMeta _totalMinorMeta = const VerificationMeta(
    'totalMinor',
  );
  @override
  late final GeneratedColumn<int> totalMinor = GeneratedColumn<int>(
    'total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidMinorMeta = const VerificationMeta(
    'paidMinor',
  );
  @override
  late final GeneratedColumn<int> paidMinor = GeneratedColumn<int>(
    'paid_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _refundedMinorMeta = const VerificationMeta(
    'refundedMinor',
  );
  @override
  late final GeneratedColumn<int> refundedMinor = GeneratedColumn<int>(
    'refunded_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditedMinorMeta = const VerificationMeta(
    'creditedMinor',
  );
  @override
  late final GeneratedColumn<int> creditedMinor = GeneratedColumn<int>(
    'credited_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _effectiveMinorMeta = const VerificationMeta(
    'effectiveMinor',
  );
  @override
  late final GeneratedColumn<int> effectiveMinor = GeneratedColumn<int>(
    'effective_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outstandingMinorMeta = const VerificationMeta(
    'outstandingMinor',
  );
  @override
  late final GeneratedColumn<int> outstandingMinor = GeneratedColumn<int>(
    'outstanding_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOpenMeta = const VerificationMeta('isOpen');
  @override
  late final GeneratedColumn<bool> isOpen = GeneratedColumn<bool>(
    'is_open',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_open" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  customFields =
      GeneratedColumn<String>(
        'custom_fields',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $TransactionsTable.$convertercustomFields,
      );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<String> linkedTransactionId =
      GeneratedColumn<String>(
        'linked_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkKindMeta = const VerificationMeta(
    'linkKind',
  );
  @override
  late final GeneratedColumn<String> linkKind = GeneratedColumn<String>(
    'link_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settlementIdMeta = const VerificationMeta(
    'settlementId',
  );
  @override
  late final GeneratedColumn<String> settlementId = GeneratedColumn<String>(
    'settlement_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<dynamic>, String>
  searchTokens = GeneratedColumn<String>(
    'search_tokens',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<dynamic>>($TransactionsTable.$convertersearchTokens);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<String> confirmedAt = GeneratedColumn<String>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedByMeta = const VerificationMeta(
    'confirmedBy',
  );
  @override
  late final GeneratedColumn<String> confirmedBy = GeneratedColumn<String>(
    'confirmed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  @override
  late final GeneratedColumn<String> cancelledAt = GeneratedColumn<String>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledByMeta = const VerificationMeta(
    'cancelledBy',
  );
  @override
  late final GeneratedColumn<String> cancelledBy = GeneratedColumn<String>(
    'cancelled_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPendingMeta = const VerificationMeta(
    'localPending',
  );
  @override
  late final GeneratedColumn<bool> localPending = GeneratedColumn<bool>(
    'local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    type,
    direction,
    status,
    categoryId,
    categoryName,
    partyId,
    partyName,
    projectId,
    projectName,
    description,
    reference,
    notes,
    paymentMethod,
    date,
    dueDate,
    receiptDate,
    lineItems,
    totalMinor,
    paidMinor,
    refundedMinor,
    creditedMinor,
    effectiveMinor,
    outstandingMinor,
    paymentStatus,
    isOpen,
    customFields,
    linkedTransactionId,
    linkKind,
    settlementId,
    searchTokens,
    version,
    createdBy,
    createdAt,
    updatedAt,
    updatedBy,
    confirmedAt,
    confirmedBy,
    cancelledAt,
    cancelledBy,
    cancelReason,
    deletedAt,
    seq,
    localPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRowData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('party_id')) {
      context.handle(
        _partyIdMeta,
        partyId.isAcceptableOrUnknown(data['party_id']!, _partyIdMeta),
      );
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('receipt_date')) {
      context.handle(
        _receiptDateMeta,
        receiptDate.isAcceptableOrUnknown(
          data['receipt_date']!,
          _receiptDateMeta,
        ),
      );
    }
    if (data.containsKey('total_minor')) {
      context.handle(
        _totalMinorMeta,
        totalMinor.isAcceptableOrUnknown(data['total_minor']!, _totalMinorMeta),
      );
    }
    if (data.containsKey('paid_minor')) {
      context.handle(
        _paidMinorMeta,
        paidMinor.isAcceptableOrUnknown(data['paid_minor']!, _paidMinorMeta),
      );
    }
    if (data.containsKey('refunded_minor')) {
      context.handle(
        _refundedMinorMeta,
        refundedMinor.isAcceptableOrUnknown(
          data['refunded_minor']!,
          _refundedMinorMeta,
        ),
      );
    }
    if (data.containsKey('credited_minor')) {
      context.handle(
        _creditedMinorMeta,
        creditedMinor.isAcceptableOrUnknown(
          data['credited_minor']!,
          _creditedMinorMeta,
        ),
      );
    }
    if (data.containsKey('effective_minor')) {
      context.handle(
        _effectiveMinorMeta,
        effectiveMinor.isAcceptableOrUnknown(
          data['effective_minor']!,
          _effectiveMinorMeta,
        ),
      );
    }
    if (data.containsKey('outstanding_minor')) {
      context.handle(
        _outstandingMinorMeta,
        outstandingMinor.isAcceptableOrUnknown(
          data['outstanding_minor']!,
          _outstandingMinorMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('is_open')) {
      context.handle(
        _isOpenMeta,
        isOpen.isAcceptableOrUnknown(data['is_open']!, _isOpenMeta),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('link_kind')) {
      context.handle(
        _linkKindMeta,
        linkKind.isAcceptableOrUnknown(data['link_kind']!, _linkKindMeta),
      );
    }
    if (data.containsKey('settlement_id')) {
      context.handle(
        _settlementIdMeta,
        settlementId.isAcceptableOrUnknown(
          data['settlement_id']!,
          _settlementIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_by')) {
      context.handle(
        _confirmedByMeta,
        confirmedBy.isAcceptableOrUnknown(
          data['confirmed_by']!,
          _confirmedByMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_by')) {
      context.handle(
        _cancelledByMeta,
        cancelledBy.isAcceptableOrUnknown(
          data['cancelled_by']!,
          _cancelledByMeta,
        ),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('local_pending')) {
      context.handle(
        _localPendingMeta,
        localPending.isAcceptableOrUnknown(
          data['local_pending']!,
          _localPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRowData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRowData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      partyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_id'],
      ),
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      receiptDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_date'],
      ),
      lineItems: $TransactionsTable.$converterlineItems.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}line_items'],
        )!,
      ),
      totalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor'],
      )!,
      paidMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_minor'],
      )!,
      refundedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refunded_minor'],
      )!,
      creditedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credited_minor'],
      )!,
      effectiveMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_minor'],
      )!,
      outstandingMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outstanding_minor'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      ),
      isOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_open'],
      )!,
      customFields: $TransactionsTable.$convertercustomFields.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}custom_fields'],
        )!,
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      linkKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_kind'],
      ),
      settlementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_id'],
      ),
      searchTokens: $TransactionsTable.$convertersearchTokens.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}search_tokens'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_at'],
      ),
      confirmedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_by'],
      ),
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancelled_at'],
      ),
      cancelledBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancelled_by'],
      ),
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      localPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_pending'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<dynamic>, String, Object?>
  $converterlineItems = const JsonListConverter();
  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $convertercustomFields = const JsonMapConverter();
  static JsonTypeConverter2<List<dynamic>, String, Object?>
  $convertersearchTokens = const JsonListConverter();
}

class TransactionRowData extends DataClass
    implements Insertable<TransactionRowData> {
  final String id;
  final String businessId;
  final String type;
  final String? direction;
  final String status;
  final String? categoryId;
  final String? categoryName;
  final String? partyId;
  final String? partyName;
  final String? projectId;
  final String? projectName;
  final String description;
  final String reference;
  final String notes;
  final String paymentMethod;

  /// `yyyy-MM-dd`: compares and sorts as text.
  final String? date;
  final String? dueDate;
  final String? receiptDate;
  final List<dynamic> lineItems;
  final int totalMinor;
  final int paidMinor;
  final int refundedMinor;
  final int creditedMinor;
  final int effectiveMinor;
  final int outstandingMinor;
  final String? paymentStatus;
  final bool isOpen;
  final Map<String, dynamic> customFields;
  final String? linkedTransactionId;
  final String? linkKind;
  final String? settlementId;

  /// A JSON array of lowercase word prefixes; searched with `json_each`.
  final List<dynamic> searchTokens;
  final int version;
  final String createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? updatedBy;
  final String? confirmedAt;
  final String? confirmedBy;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;
  final String? deletedAt;
  final int seq;
  final bool localPending;
  const TransactionRowData({
    required this.id,
    required this.businessId,
    required this.type,
    this.direction,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.partyId,
    this.partyName,
    this.projectId,
    this.projectName,
    required this.description,
    required this.reference,
    required this.notes,
    required this.paymentMethod,
    this.date,
    this.dueDate,
    this.receiptDate,
    required this.lineItems,
    required this.totalMinor,
    required this.paidMinor,
    required this.refundedMinor,
    required this.creditedMinor,
    required this.effectiveMinor,
    required this.outstandingMinor,
    this.paymentStatus,
    required this.isOpen,
    required this.customFields,
    this.linkedTransactionId,
    this.linkKind,
    this.settlementId,
    required this.searchTokens,
    required this.version,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.confirmedAt,
    this.confirmedBy,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
    this.deletedAt,
    required this.seq,
    required this.localPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || direction != null) {
      map['direction'] = Variable<String>(direction);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || partyId != null) {
      map['party_id'] = Variable<String>(partyId);
    }
    if (!nullToAbsent || partyName != null) {
      map['party_name'] = Variable<String>(partyName);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['description'] = Variable<String>(description);
    map['reference'] = Variable<String>(reference);
    map['notes'] = Variable<String>(notes);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || receiptDate != null) {
      map['receipt_date'] = Variable<String>(receiptDate);
    }
    {
      map['line_items'] = Variable<String>(
        $TransactionsTable.$converterlineItems.toSql(lineItems),
      );
    }
    map['total_minor'] = Variable<int>(totalMinor);
    map['paid_minor'] = Variable<int>(paidMinor);
    map['refunded_minor'] = Variable<int>(refundedMinor);
    map['credited_minor'] = Variable<int>(creditedMinor);
    map['effective_minor'] = Variable<int>(effectiveMinor);
    map['outstanding_minor'] = Variable<int>(outstandingMinor);
    if (!nullToAbsent || paymentStatus != null) {
      map['payment_status'] = Variable<String>(paymentStatus);
    }
    map['is_open'] = Variable<bool>(isOpen);
    {
      map['custom_fields'] = Variable<String>(
        $TransactionsTable.$convertercustomFields.toSql(customFields),
      );
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<String>(linkedTransactionId);
    }
    if (!nullToAbsent || linkKind != null) {
      map['link_kind'] = Variable<String>(linkKind);
    }
    if (!nullToAbsent || settlementId != null) {
      map['settlement_id'] = Variable<String>(settlementId);
    }
    {
      map['search_tokens'] = Variable<String>(
        $TransactionsTable.$convertersearchTokens.toSql(searchTokens),
      );
    }
    map['version'] = Variable<int>(version);
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<String>(confirmedAt);
    }
    if (!nullToAbsent || confirmedBy != null) {
      map['confirmed_by'] = Variable<String>(confirmedBy);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<String>(cancelledAt);
    }
    if (!nullToAbsent || cancelledBy != null) {
      map['cancelled_by'] = Variable<String>(cancelledBy);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['seq'] = Variable<int>(seq);
    map['local_pending'] = Variable<bool>(localPending);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      type: Value(type),
      direction: direction == null && nullToAbsent
          ? const Value.absent()
          : Value(direction),
      status: Value(status),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      partyId: partyId == null && nullToAbsent
          ? const Value.absent()
          : Value(partyId),
      partyName: partyName == null && nullToAbsent
          ? const Value.absent()
          : Value(partyName),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      description: Value(description),
      reference: Value(reference),
      notes: Value(notes),
      paymentMethod: Value(paymentMethod),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      receiptDate: receiptDate == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptDate),
      lineItems: Value(lineItems),
      totalMinor: Value(totalMinor),
      paidMinor: Value(paidMinor),
      refundedMinor: Value(refundedMinor),
      creditedMinor: Value(creditedMinor),
      effectiveMinor: Value(effectiveMinor),
      outstandingMinor: Value(outstandingMinor),
      paymentStatus: paymentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentStatus),
      isOpen: Value(isOpen),
      customFields: Value(customFields),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      linkKind: linkKind == null && nullToAbsent
          ? const Value.absent()
          : Value(linkKind),
      settlementId: settlementId == null && nullToAbsent
          ? const Value.absent()
          : Value(settlementId),
      searchTokens: Value(searchTokens),
      version: Value(version),
      createdBy: Value(createdBy),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      confirmedBy: confirmedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedBy),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      cancelledBy: cancelledBy == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledBy),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      seq: Value(seq),
      localPending: Value(localPending),
    );
  }

  factory TransactionRowData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRowData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      type: serializer.fromJson<String>(json['type']),
      direction: serializer.fromJson<String?>(json['direction']),
      status: serializer.fromJson<String>(json['status']),
      categoryId: serializer.fromJson<String?>(json['category_id']),
      categoryName: serializer.fromJson<String?>(json['category_name']),
      partyId: serializer.fromJson<String?>(json['party_id']),
      partyName: serializer.fromJson<String?>(json['party_name']),
      projectId: serializer.fromJson<String?>(json['project_id']),
      projectName: serializer.fromJson<String?>(json['project_name']),
      description: serializer.fromJson<String>(json['description']),
      reference: serializer.fromJson<String>(json['reference']),
      notes: serializer.fromJson<String>(json['notes']),
      paymentMethod: serializer.fromJson<String>(json['payment_method']),
      date: serializer.fromJson<String?>(json['date']),
      dueDate: serializer.fromJson<String?>(json['due_date']),
      receiptDate: serializer.fromJson<String?>(json['receipt_date']),
      lineItems: $TransactionsTable.$converterlineItems.fromJson(
        serializer.fromJson<Object?>(json['line_items']),
      ),
      totalMinor: serializer.fromJson<int>(json['total_minor']),
      paidMinor: serializer.fromJson<int>(json['paid_minor']),
      refundedMinor: serializer.fromJson<int>(json['refunded_minor']),
      creditedMinor: serializer.fromJson<int>(json['credited_minor']),
      effectiveMinor: serializer.fromJson<int>(json['effective_minor']),
      outstandingMinor: serializer.fromJson<int>(json['outstanding_minor']),
      paymentStatus: serializer.fromJson<String?>(json['payment_status']),
      isOpen: serializer.fromJson<bool>(json['is_open']),
      customFields: $TransactionsTable.$convertercustomFields.fromJson(
        serializer.fromJson<Object?>(json['custom_fields']),
      ),
      linkedTransactionId: serializer.fromJson<String?>(
        json['linked_transaction_id'],
      ),
      linkKind: serializer.fromJson<String?>(json['link_kind']),
      settlementId: serializer.fromJson<String?>(json['settlement_id']),
      searchTokens: $TransactionsTable.$convertersearchTokens.fromJson(
        serializer.fromJson<Object?>(json['search_tokens']),
      ),
      version: serializer.fromJson<int>(json['version']),
      createdBy: serializer.fromJson<String>(json['created_by']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      updatedBy: serializer.fromJson<String?>(json['updated_by']),
      confirmedAt: serializer.fromJson<String?>(json['confirmed_at']),
      confirmedBy: serializer.fromJson<String?>(json['confirmed_by']),
      cancelledAt: serializer.fromJson<String?>(json['cancelled_at']),
      cancelledBy: serializer.fromJson<String?>(json['cancelled_by']),
      cancelReason: serializer.fromJson<String?>(json['cancel_reason']),
      deletedAt: serializer.fromJson<String?>(json['deleted_at']),
      seq: serializer.fromJson<int>(json['seq']),
      localPending: serializer.fromJson<bool>(json['local_pending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'business_id': serializer.toJson<String>(businessId),
      'type': serializer.toJson<String>(type),
      'direction': serializer.toJson<String?>(direction),
      'status': serializer.toJson<String>(status),
      'category_id': serializer.toJson<String?>(categoryId),
      'category_name': serializer.toJson<String?>(categoryName),
      'party_id': serializer.toJson<String?>(partyId),
      'party_name': serializer.toJson<String?>(partyName),
      'project_id': serializer.toJson<String?>(projectId),
      'project_name': serializer.toJson<String?>(projectName),
      'description': serializer.toJson<String>(description),
      'reference': serializer.toJson<String>(reference),
      'notes': serializer.toJson<String>(notes),
      'payment_method': serializer.toJson<String>(paymentMethod),
      'date': serializer.toJson<String?>(date),
      'due_date': serializer.toJson<String?>(dueDate),
      'receipt_date': serializer.toJson<String?>(receiptDate),
      'line_items': serializer.toJson<Object?>(
        $TransactionsTable.$converterlineItems.toJson(lineItems),
      ),
      'total_minor': serializer.toJson<int>(totalMinor),
      'paid_minor': serializer.toJson<int>(paidMinor),
      'refunded_minor': serializer.toJson<int>(refundedMinor),
      'credited_minor': serializer.toJson<int>(creditedMinor),
      'effective_minor': serializer.toJson<int>(effectiveMinor),
      'outstanding_minor': serializer.toJson<int>(outstandingMinor),
      'payment_status': serializer.toJson<String?>(paymentStatus),
      'is_open': serializer.toJson<bool>(isOpen),
      'custom_fields': serializer.toJson<Object?>(
        $TransactionsTable.$convertercustomFields.toJson(customFields),
      ),
      'linked_transaction_id': serializer.toJson<String?>(linkedTransactionId),
      'link_kind': serializer.toJson<String?>(linkKind),
      'settlement_id': serializer.toJson<String?>(settlementId),
      'search_tokens': serializer.toJson<Object?>(
        $TransactionsTable.$convertersearchTokens.toJson(searchTokens),
      ),
      'version': serializer.toJson<int>(version),
      'created_by': serializer.toJson<String>(createdBy),
      'created_at': serializer.toJson<String?>(createdAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'updated_by': serializer.toJson<String?>(updatedBy),
      'confirmed_at': serializer.toJson<String?>(confirmedAt),
      'confirmed_by': serializer.toJson<String?>(confirmedBy),
      'cancelled_at': serializer.toJson<String?>(cancelledAt),
      'cancelled_by': serializer.toJson<String?>(cancelledBy),
      'cancel_reason': serializer.toJson<String?>(cancelReason),
      'deleted_at': serializer.toJson<String?>(deletedAt),
      'seq': serializer.toJson<int>(seq),
      'local_pending': serializer.toJson<bool>(localPending),
    };
  }

  TransactionRowData copyWith({
    String? id,
    String? businessId,
    String? type,
    Value<String?> direction = const Value.absent(),
    String? status,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<String?> partyId = const Value.absent(),
    Value<String?> partyName = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    String? description,
    String? reference,
    String? notes,
    String? paymentMethod,
    Value<String?> date = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<String?> receiptDate = const Value.absent(),
    List<dynamic>? lineItems,
    int? totalMinor,
    int? paidMinor,
    int? refundedMinor,
    int? creditedMinor,
    int? effectiveMinor,
    int? outstandingMinor,
    Value<String?> paymentStatus = const Value.absent(),
    bool? isOpen,
    Map<String, dynamic>? customFields,
    Value<String?> linkedTransactionId = const Value.absent(),
    Value<String?> linkKind = const Value.absent(),
    Value<String?> settlementId = const Value.absent(),
    List<dynamic>? searchTokens,
    int? version,
    String? createdBy,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    Value<String?> confirmedAt = const Value.absent(),
    Value<String?> confirmedBy = const Value.absent(),
    Value<String?> cancelledAt = const Value.absent(),
    Value<String?> cancelledBy = const Value.absent(),
    Value<String?> cancelReason = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    int? seq,
    bool? localPending,
  }) => TransactionRowData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    type: type ?? this.type,
    direction: direction.present ? direction.value : this.direction,
    status: status ?? this.status,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    partyId: partyId.present ? partyId.value : this.partyId,
    partyName: partyName.present ? partyName.value : this.partyName,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectName: projectName.present ? projectName.value : this.projectName,
    description: description ?? this.description,
    reference: reference ?? this.reference,
    notes: notes ?? this.notes,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    date: date.present ? date.value : this.date,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    receiptDate: receiptDate.present ? receiptDate.value : this.receiptDate,
    lineItems: lineItems ?? this.lineItems,
    totalMinor: totalMinor ?? this.totalMinor,
    paidMinor: paidMinor ?? this.paidMinor,
    refundedMinor: refundedMinor ?? this.refundedMinor,
    creditedMinor: creditedMinor ?? this.creditedMinor,
    effectiveMinor: effectiveMinor ?? this.effectiveMinor,
    outstandingMinor: outstandingMinor ?? this.outstandingMinor,
    paymentStatus: paymentStatus.present
        ? paymentStatus.value
        : this.paymentStatus,
    isOpen: isOpen ?? this.isOpen,
    customFields: customFields ?? this.customFields,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    linkKind: linkKind.present ? linkKind.value : this.linkKind,
    settlementId: settlementId.present ? settlementId.value : this.settlementId,
    searchTokens: searchTokens ?? this.searchTokens,
    version: version ?? this.version,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    confirmedBy: confirmedBy.present ? confirmedBy.value : this.confirmedBy,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    cancelledBy: cancelledBy.present ? cancelledBy.value : this.cancelledBy,
    cancelReason: cancelReason.present ? cancelReason.value : this.cancelReason,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    seq: seq ?? this.seq,
    localPending: localPending ?? this.localPending,
  );
  TransactionRowData copyWithCompanion(TransactionsCompanion data) {
    return TransactionRowData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      type: data.type.present ? data.type.value : this.type,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      partyId: data.partyId.present ? data.partyId.value : this.partyId,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      description: data.description.present
          ? data.description.value
          : this.description,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      receiptDate: data.receiptDate.present
          ? data.receiptDate.value
          : this.receiptDate,
      lineItems: data.lineItems.present ? data.lineItems.value : this.lineItems,
      totalMinor: data.totalMinor.present
          ? data.totalMinor.value
          : this.totalMinor,
      paidMinor: data.paidMinor.present ? data.paidMinor.value : this.paidMinor,
      refundedMinor: data.refundedMinor.present
          ? data.refundedMinor.value
          : this.refundedMinor,
      creditedMinor: data.creditedMinor.present
          ? data.creditedMinor.value
          : this.creditedMinor,
      effectiveMinor: data.effectiveMinor.present
          ? data.effectiveMinor.value
          : this.effectiveMinor,
      outstandingMinor: data.outstandingMinor.present
          ? data.outstandingMinor.value
          : this.outstandingMinor,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      isOpen: data.isOpen.present ? data.isOpen.value : this.isOpen,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      linkKind: data.linkKind.present ? data.linkKind.value : this.linkKind,
      settlementId: data.settlementId.present
          ? data.settlementId.value
          : this.settlementId,
      searchTokens: data.searchTokens.present
          ? data.searchTokens.value
          : this.searchTokens,
      version: data.version.present ? data.version.value : this.version,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      confirmedBy: data.confirmedBy.present
          ? data.confirmedBy.value
          : this.confirmedBy,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      cancelledBy: data.cancelledBy.present
          ? data.cancelledBy.value
          : this.cancelledBy,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
      localPending: data.localPending.present
          ? data.localPending.value
          : this.localPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRowData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('partyId: $partyId, ')
          ..write('partyName: $partyName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('description: $description, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('lineItems: $lineItems, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('paidMinor: $paidMinor, ')
          ..write('refundedMinor: $refundedMinor, ')
          ..write('creditedMinor: $creditedMinor, ')
          ..write('effectiveMinor: $effectiveMinor, ')
          ..write('outstandingMinor: $outstandingMinor, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('isOpen: $isOpen, ')
          ..write('customFields: $customFields, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('linkKind: $linkKind, ')
          ..write('settlementId: $settlementId, ')
          ..write('searchTokens: $searchTokens, ')
          ..write('version: $version, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('confirmedBy: $confirmedBy, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelledBy: $cancelledBy, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    type,
    direction,
    status,
    categoryId,
    categoryName,
    partyId,
    partyName,
    projectId,
    projectName,
    description,
    reference,
    notes,
    paymentMethod,
    date,
    dueDate,
    receiptDate,
    lineItems,
    totalMinor,
    paidMinor,
    refundedMinor,
    creditedMinor,
    effectiveMinor,
    outstandingMinor,
    paymentStatus,
    isOpen,
    customFields,
    linkedTransactionId,
    linkKind,
    settlementId,
    searchTokens,
    version,
    createdBy,
    createdAt,
    updatedAt,
    updatedBy,
    confirmedAt,
    confirmedBy,
    cancelledAt,
    cancelledBy,
    cancelReason,
    deletedAt,
    seq,
    localPending,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRowData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.type == this.type &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.partyId == this.partyId &&
          other.partyName == this.partyName &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.description == this.description &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.paymentMethod == this.paymentMethod &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.receiptDate == this.receiptDate &&
          other.lineItems == this.lineItems &&
          other.totalMinor == this.totalMinor &&
          other.paidMinor == this.paidMinor &&
          other.refundedMinor == this.refundedMinor &&
          other.creditedMinor == this.creditedMinor &&
          other.effectiveMinor == this.effectiveMinor &&
          other.outstandingMinor == this.outstandingMinor &&
          other.paymentStatus == this.paymentStatus &&
          other.isOpen == this.isOpen &&
          other.customFields == this.customFields &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.linkKind == this.linkKind &&
          other.settlementId == this.settlementId &&
          other.searchTokens == this.searchTokens &&
          other.version == this.version &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.confirmedAt == this.confirmedAt &&
          other.confirmedBy == this.confirmedBy &&
          other.cancelledAt == this.cancelledAt &&
          other.cancelledBy == this.cancelledBy &&
          other.cancelReason == this.cancelReason &&
          other.deletedAt == this.deletedAt &&
          other.seq == this.seq &&
          other.localPending == this.localPending);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRowData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> type;
  final Value<String?> direction;
  final Value<String> status;
  final Value<String?> categoryId;
  final Value<String?> categoryName;
  final Value<String?> partyId;
  final Value<String?> partyName;
  final Value<String?> projectId;
  final Value<String?> projectName;
  final Value<String> description;
  final Value<String> reference;
  final Value<String> notes;
  final Value<String> paymentMethod;
  final Value<String?> date;
  final Value<String?> dueDate;
  final Value<String?> receiptDate;
  final Value<List<dynamic>> lineItems;
  final Value<int> totalMinor;
  final Value<int> paidMinor;
  final Value<int> refundedMinor;
  final Value<int> creditedMinor;
  final Value<int> effectiveMinor;
  final Value<int> outstandingMinor;
  final Value<String?> paymentStatus;
  final Value<bool> isOpen;
  final Value<Map<String, dynamic>> customFields;
  final Value<String?> linkedTransactionId;
  final Value<String?> linkKind;
  final Value<String?> settlementId;
  final Value<List<dynamic>> searchTokens;
  final Value<int> version;
  final Value<String> createdBy;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> updatedBy;
  final Value<String?> confirmedAt;
  final Value<String?> confirmedBy;
  final Value<String?> cancelledAt;
  final Value<String?> cancelledBy;
  final Value<String?> cancelReason;
  final Value<String?> deletedAt;
  final Value<int> seq;
  final Value<bool> localPending;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.type = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.partyId = const Value.absent(),
    this.partyName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.description = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.lineItems = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.paidMinor = const Value.absent(),
    this.refundedMinor = const Value.absent(),
    this.creditedMinor = const Value.absent(),
    this.effectiveMinor = const Value.absent(),
    this.outstandingMinor = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.customFields = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.linkKind = const Value.absent(),
    this.settlementId = const Value.absent(),
    this.searchTokens = const Value.absent(),
    this.version = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.confirmedBy = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelledBy = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String businessId,
    this.type = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.partyId = const Value.absent(),
    this.partyName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.description = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.lineItems = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.paidMinor = const Value.absent(),
    this.refundedMinor = const Value.absent(),
    this.creditedMinor = const Value.absent(),
    this.effectiveMinor = const Value.absent(),
    this.outstandingMinor = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.customFields = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.linkKind = const Value.absent(),
    this.settlementId = const Value.absent(),
    this.searchTokens = const Value.absent(),
    this.version = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.confirmedBy = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.cancelledBy = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.localPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<TransactionRowData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? type,
    Expression<String>? direction,
    Expression<String>? status,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<String>? partyId,
    Expression<String>? partyName,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? description,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<String>? paymentMethod,
    Expression<String>? date,
    Expression<String>? dueDate,
    Expression<String>? receiptDate,
    Expression<String>? lineItems,
    Expression<int>? totalMinor,
    Expression<int>? paidMinor,
    Expression<int>? refundedMinor,
    Expression<int>? creditedMinor,
    Expression<int>? effectiveMinor,
    Expression<int>? outstandingMinor,
    Expression<String>? paymentStatus,
    Expression<bool>? isOpen,
    Expression<String>? customFields,
    Expression<String>? linkedTransactionId,
    Expression<String>? linkKind,
    Expression<String>? settlementId,
    Expression<String>? searchTokens,
    Expression<int>? version,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? updatedBy,
    Expression<String>? confirmedAt,
    Expression<String>? confirmedBy,
    Expression<String>? cancelledAt,
    Expression<String>? cancelledBy,
    Expression<String>? cancelReason,
    Expression<String>? deletedAt,
    Expression<int>? seq,
    Expression<bool>? localPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (type != null) 'type': type,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (partyId != null) 'party_id': partyId,
      if (partyName != null) 'party_name': partyName,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (description != null) 'description': description,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (lineItems != null) 'line_items': lineItems,
      if (totalMinor != null) 'total_minor': totalMinor,
      if (paidMinor != null) 'paid_minor': paidMinor,
      if (refundedMinor != null) 'refunded_minor': refundedMinor,
      if (creditedMinor != null) 'credited_minor': creditedMinor,
      if (effectiveMinor != null) 'effective_minor': effectiveMinor,
      if (outstandingMinor != null) 'outstanding_minor': outstandingMinor,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (isOpen != null) 'is_open': isOpen,
      if (customFields != null) 'custom_fields': customFields,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (linkKind != null) 'link_kind': linkKind,
      if (settlementId != null) 'settlement_id': settlementId,
      if (searchTokens != null) 'search_tokens': searchTokens,
      if (version != null) 'version': version,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (confirmedBy != null) 'confirmed_by': confirmedBy,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (cancelledBy != null) 'cancelled_by': cancelledBy,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (seq != null) 'seq': seq,
      if (localPending != null) 'local_pending': localPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? type,
    Value<String?>? direction,
    Value<String>? status,
    Value<String?>? categoryId,
    Value<String?>? categoryName,
    Value<String?>? partyId,
    Value<String?>? partyName,
    Value<String?>? projectId,
    Value<String?>? projectName,
    Value<String>? description,
    Value<String>? reference,
    Value<String>? notes,
    Value<String>? paymentMethod,
    Value<String?>? date,
    Value<String?>? dueDate,
    Value<String?>? receiptDate,
    Value<List<dynamic>>? lineItems,
    Value<int>? totalMinor,
    Value<int>? paidMinor,
    Value<int>? refundedMinor,
    Value<int>? creditedMinor,
    Value<int>? effectiveMinor,
    Value<int>? outstandingMinor,
    Value<String?>? paymentStatus,
    Value<bool>? isOpen,
    Value<Map<String, dynamic>>? customFields,
    Value<String?>? linkedTransactionId,
    Value<String?>? linkKind,
    Value<String?>? settlementId,
    Value<List<dynamic>>? searchTokens,
    Value<int>? version,
    Value<String>? createdBy,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? updatedBy,
    Value<String?>? confirmedAt,
    Value<String?>? confirmedBy,
    Value<String?>? cancelledAt,
    Value<String?>? cancelledBy,
    Value<String?>? cancelReason,
    Value<String?>? deletedAt,
    Value<int>? seq,
    Value<bool>? localPending,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      receiptDate: receiptDate ?? this.receiptDate,
      lineItems: lineItems ?? this.lineItems,
      totalMinor: totalMinor ?? this.totalMinor,
      paidMinor: paidMinor ?? this.paidMinor,
      refundedMinor: refundedMinor ?? this.refundedMinor,
      creditedMinor: creditedMinor ?? this.creditedMinor,
      effectiveMinor: effectiveMinor ?? this.effectiveMinor,
      outstandingMinor: outstandingMinor ?? this.outstandingMinor,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isOpen: isOpen ?? this.isOpen,
      customFields: customFields ?? this.customFields,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      linkKind: linkKind ?? this.linkKind,
      settlementId: settlementId ?? this.settlementId,
      searchTokens: searchTokens ?? this.searchTokens,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      deletedAt: deletedAt ?? this.deletedAt,
      seq: seq ?? this.seq,
      localPending: localPending ?? this.localPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (partyId.present) {
      map['party_id'] = Variable<String>(partyId.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (receiptDate.present) {
      map['receipt_date'] = Variable<String>(receiptDate.value);
    }
    if (lineItems.present) {
      map['line_items'] = Variable<String>(
        $TransactionsTable.$converterlineItems.toSql(lineItems.value),
      );
    }
    if (totalMinor.present) {
      map['total_minor'] = Variable<int>(totalMinor.value);
    }
    if (paidMinor.present) {
      map['paid_minor'] = Variable<int>(paidMinor.value);
    }
    if (refundedMinor.present) {
      map['refunded_minor'] = Variable<int>(refundedMinor.value);
    }
    if (creditedMinor.present) {
      map['credited_minor'] = Variable<int>(creditedMinor.value);
    }
    if (effectiveMinor.present) {
      map['effective_minor'] = Variable<int>(effectiveMinor.value);
    }
    if (outstandingMinor.present) {
      map['outstanding_minor'] = Variable<int>(outstandingMinor.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (isOpen.present) {
      map['is_open'] = Variable<bool>(isOpen.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(
        $TransactionsTable.$convertercustomFields.toSql(customFields.value),
      );
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<String>(
        linkedTransactionId.value,
      );
    }
    if (linkKind.present) {
      map['link_kind'] = Variable<String>(linkKind.value);
    }
    if (settlementId.present) {
      map['settlement_id'] = Variable<String>(settlementId.value);
    }
    if (searchTokens.present) {
      map['search_tokens'] = Variable<String>(
        $TransactionsTable.$convertersearchTokens.toSql(searchTokens.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<String>(confirmedAt.value);
    }
    if (confirmedBy.present) {
      map['confirmed_by'] = Variable<String>(confirmedBy.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<String>(cancelledAt.value);
    }
    if (cancelledBy.present) {
      map['cancelled_by'] = Variable<String>(cancelledBy.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (localPending.present) {
      map['local_pending'] = Variable<bool>(localPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('partyId: $partyId, ')
          ..write('partyName: $partyName, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('description: $description, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('lineItems: $lineItems, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('paidMinor: $paidMinor, ')
          ..write('refundedMinor: $refundedMinor, ')
          ..write('creditedMinor: $creditedMinor, ')
          ..write('effectiveMinor: $effectiveMinor, ')
          ..write('outstandingMinor: $outstandingMinor, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('isOpen: $isOpen, ')
          ..write('customFields: $customFields, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('linkKind: $linkKind, ')
          ..write('settlementId: $settlementId, ')
          ..write('searchTokens: $searchTokens, ')
          ..write('version: $version, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('confirmedBy: $confirmedBy, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('cancelledBy: $cancelledBy, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('seq: $seq, ')
          ..write('localPending: $localPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettlementsTable extends Settlements
    with TableInfo<$SettlementsTable, SettlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('payment'),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  balanceAfter =
      GeneratedColumn<String>(
        'balance_after',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $SettlementsTable.$converterbalanceAfter,
      );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<String> linkedTransactionId =
      GeneratedColumn<String>(
        'linked_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedMeta = const VerificationMeta('voided');
  @override
  late final GeneratedColumn<bool> voided = GeneratedColumn<bool>(
    'voided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    transactionId,
    id,
    kind,
    amountMinor,
    date,
    method,
    note,
    balanceAfter,
    linkedTransactionId,
    createdBy,
    createdAt,
    voided,
    updatedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('voided')) {
      context.handle(
        _voidedMeta,
        voided.isAcceptableOrUnknown(data['voided']!, _voidedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, id};
  @override
  SettlementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettlementRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      balanceAfter: $SettlementsTable.$converterbalanceAfter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}balance_after'],
        )!,
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      voided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}voided'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $SettlementsTable createAlias(String alias) {
    return $SettlementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterbalanceAfter = const JsonMapConverter();
}

class SettlementRow extends DataClass implements Insertable<SettlementRow> {
  final String businessId;
  final String transactionId;
  final String id;
  final String kind;
  final int amountMinor;
  final String date;
  final String method;
  final String note;
  final Map<String, dynamic> balanceAfter;
  final String? linkedTransactionId;
  final String createdBy;
  final String? createdAt;
  final bool voided;
  final String? updatedAt;
  final int seq;
  const SettlementRow({
    required this.businessId,
    required this.transactionId,
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.date,
    required this.method,
    required this.note,
    required this.balanceAfter,
    this.linkedTransactionId,
    required this.createdBy,
    this.createdAt,
    required this.voided,
    this.updatedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['transaction_id'] = Variable<String>(transactionId);
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['date'] = Variable<String>(date);
    map['method'] = Variable<String>(method);
    map['note'] = Variable<String>(note);
    {
      map['balance_after'] = Variable<String>(
        $SettlementsTable.$converterbalanceAfter.toSql(balanceAfter),
      );
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<String>(linkedTransactionId);
    }
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    map['voided'] = Variable<bool>(voided);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      businessId: Value(businessId),
      transactionId: Value(transactionId),
      id: Value(id),
      kind: Value(kind),
      amountMinor: Value(amountMinor),
      date: Value(date),
      method: Value(method),
      note: Value(note),
      balanceAfter: Value(balanceAfter),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      createdBy: Value(createdBy),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      voided: Value(voided),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
    );
  }

  factory SettlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettlementRow(
      businessId: serializer.fromJson<String>(json['business_id']),
      transactionId: serializer.fromJson<String>(json['transaction_id']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
      date: serializer.fromJson<String>(json['date']),
      method: serializer.fromJson<String>(json['method']),
      note: serializer.fromJson<String>(json['note']),
      balanceAfter: $SettlementsTable.$converterbalanceAfter.fromJson(
        serializer.fromJson<Object?>(json['balance_after']),
      ),
      linkedTransactionId: serializer.fromJson<String?>(
        json['linked_transaction_id'],
      ),
      createdBy: serializer.fromJson<String>(json['created_by']),
      createdAt: serializer.fromJson<String?>(json['created_at']),
      voided: serializer.fromJson<bool>(json['voided']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'transaction_id': serializer.toJson<String>(transactionId),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'amount_minor': serializer.toJson<int>(amountMinor),
      'date': serializer.toJson<String>(date),
      'method': serializer.toJson<String>(method),
      'note': serializer.toJson<String>(note),
      'balance_after': serializer.toJson<Object?>(
        $SettlementsTable.$converterbalanceAfter.toJson(balanceAfter),
      ),
      'linked_transaction_id': serializer.toJson<String?>(linkedTransactionId),
      'created_by': serializer.toJson<String>(createdBy),
      'created_at': serializer.toJson<String?>(createdAt),
      'voided': serializer.toJson<bool>(voided),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SettlementRow copyWith({
    String? businessId,
    String? transactionId,
    String? id,
    String? kind,
    int? amountMinor,
    String? date,
    String? method,
    String? note,
    Map<String, dynamic>? balanceAfter,
    Value<String?> linkedTransactionId = const Value.absent(),
    String? createdBy,
    Value<String?> createdAt = const Value.absent(),
    bool? voided,
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
  }) => SettlementRow(
    businessId: businessId ?? this.businessId,
    transactionId: transactionId ?? this.transactionId,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    method: method ?? this.method,
    note: note ?? this.note,
    balanceAfter: balanceAfter ?? this.balanceAfter,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    voided: voided ?? this.voided,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
  );
  SettlementRow copyWithCompanion(SettlementsCompanion data) {
    return SettlementRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      date: data.date.present ? data.date.value : this.date,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      balanceAfter: data.balanceAfter.present
          ? data.balanceAfter.value
          : this.balanceAfter,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      voided: data.voided.present ? data.voided.value : this.voided,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettlementRow(')
          ..write('businessId: $businessId, ')
          ..write('transactionId: $transactionId, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('voided: $voided, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    transactionId,
    id,
    kind,
    amountMinor,
    date,
    method,
    note,
    balanceAfter,
    linkedTransactionId,
    createdBy,
    createdAt,
    voided,
    updatedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettlementRow &&
          other.businessId == this.businessId &&
          other.transactionId == this.transactionId &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.date == this.date &&
          other.method == this.method &&
          other.note == this.note &&
          other.balanceAfter == this.balanceAfter &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.voided == this.voided &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq);
}

class SettlementsCompanion extends UpdateCompanion<SettlementRow> {
  final Value<String> businessId;
  final Value<String> transactionId;
  final Value<String> id;
  final Value<String> kind;
  final Value<int> amountMinor;
  final Value<String> date;
  final Value<String> method;
  final Value<String> note;
  final Value<Map<String, dynamic>> balanceAfter;
  final Value<String?> linkedTransactionId;
  final Value<String> createdBy;
  final Value<String?> createdAt;
  final Value<bool> voided;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.businessId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.voided = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    required String businessId,
    required String transactionId,
    required String id,
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.voided = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       transactionId = Value(transactionId),
       id = Value(id);
  static Insertable<SettlementRow> custom({
    Expression<String>? businessId,
    Expression<String>? transactionId,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? date,
    Expression<String>? method,
    Expression<String>? note,
    Expression<String>? balanceAfter,
    Expression<String>? linkedTransactionId,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<bool>? voided,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (date != null) 'date': date,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (voided != null) 'voided': voided,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith({
    Value<String>? businessId,
    Value<String>? transactionId,
    Value<String>? id,
    Value<String>? kind,
    Value<int>? amountMinor,
    Value<String>? date,
    Value<String>? method,
    Value<String>? note,
    Value<Map<String, dynamic>>? balanceAfter,
    Value<String?>? linkedTransactionId,
    Value<String>? createdBy,
    Value<String?>? createdAt,
    Value<bool>? voided,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return SettlementsCompanion(
      businessId: businessId ?? this.businessId,
      transactionId: transactionId ?? this.transactionId,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      method: method ?? this.method,
      note: note ?? this.note,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      voided: voided ?? this.voided,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<String>(
        $SettlementsTable.$converterbalanceAfter.toSql(balanceAfter.value),
      );
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<String>(
        linkedTransactionId.value,
      );
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (voided.present) {
      map['voided'] = Variable<bool>(voided.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('businessId: $businessId, ')
          ..write('transactionId: $transactionId, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('voided: $voided, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('invoice'),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _settlementIdMeta = const VerificationMeta(
    'settlementId',
  );
  @override
  late final GeneratedColumn<String> settlementId = GeneratedColumn<String>(
    'settlement_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, dynamic>>($DocumentsTable.$convertersnapshot);
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<String> issuedAt = GeneratedColumn<String>(
    'issued_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuedByMeta = const VerificationMeta(
    'issuedBy',
  );
  @override
  late final GeneratedColumn<String> issuedBy = GeneratedColumn<String>(
    'issued_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedMeta = const VerificationMeta('voided');
  @override
  late final GeneratedColumn<bool> voided = GeneratedColumn<bool>(
    'voided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<String> voidedAt = GeneratedColumn<String>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    id,
    type,
    number,
    transactionId,
    settlementId,
    snapshot,
    issuedAt,
    issuedBy,
    voided,
    voidedAt,
    updatedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('settlement_id')) {
      context.handle(
        _settlementIdMeta,
        settlementId.isAcceptableOrUnknown(
          data['settlement_id']!,
          _settlementIdMeta,
        ),
      );
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    }
    if (data.containsKey('issued_by')) {
      context.handle(
        _issuedByMeta,
        issuedBy.isAcceptableOrUnknown(data['issued_by']!, _issuedByMeta),
      );
    }
    if (data.containsKey('voided')) {
      context.handle(
        _voidedMeta,
        voided.isAcceptableOrUnknown(data['voided']!, _voidedMeta),
      );
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      settlementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_id'],
      ),
      snapshot: $DocumentsTable.$convertersnapshot.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}snapshot'],
        )!,
      ),
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_at'],
      ),
      issuedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_by'],
      ),
      voided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}voided'],
      )!,
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $convertersnapshot = const JsonMapConverter();
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String businessId;
  final String id;
  final String type;
  final String number;
  final String transactionId;
  final String? settlementId;
  final Map<String, dynamic> snapshot;
  final String? issuedAt;
  final String? issuedBy;
  final bool voided;
  final String? voidedAt;
  final String? updatedAt;
  final int seq;
  const DocumentRow({
    required this.businessId,
    required this.id,
    required this.type,
    required this.number,
    required this.transactionId,
    this.settlementId,
    required this.snapshot,
    this.issuedAt,
    this.issuedBy,
    required this.voided,
    this.voidedAt,
    this.updatedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['number'] = Variable<String>(number);
    map['transaction_id'] = Variable<String>(transactionId);
    if (!nullToAbsent || settlementId != null) {
      map['settlement_id'] = Variable<String>(settlementId);
    }
    {
      map['snapshot'] = Variable<String>(
        $DocumentsTable.$convertersnapshot.toSql(snapshot),
      );
    }
    if (!nullToAbsent || issuedAt != null) {
      map['issued_at'] = Variable<String>(issuedAt);
    }
    if (!nullToAbsent || issuedBy != null) {
      map['issued_by'] = Variable<String>(issuedBy);
    }
    map['voided'] = Variable<bool>(voided);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<String>(voidedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      businessId: Value(businessId),
      id: Value(id),
      type: Value(type),
      number: Value(number),
      transactionId: Value(transactionId),
      settlementId: settlementId == null && nullToAbsent
          ? const Value.absent()
          : Value(settlementId),
      snapshot: Value(snapshot),
      issuedAt: issuedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(issuedAt),
      issuedBy: issuedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(issuedBy),
      voided: Value(voided),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      businessId: serializer.fromJson<String>(json['business_id']),
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      number: serializer.fromJson<String>(json['number']),
      transactionId: serializer.fromJson<String>(json['transaction_id']),
      settlementId: serializer.fromJson<String?>(json['settlement_id']),
      snapshot: $DocumentsTable.$convertersnapshot.fromJson(
        serializer.fromJson<Object?>(json['snapshot']),
      ),
      issuedAt: serializer.fromJson<String?>(json['issued_at']),
      issuedBy: serializer.fromJson<String?>(json['issued_by']),
      voided: serializer.fromJson<bool>(json['voided']),
      voidedAt: serializer.fromJson<String?>(json['voided_at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'number': serializer.toJson<String>(number),
      'transaction_id': serializer.toJson<String>(transactionId),
      'settlement_id': serializer.toJson<String?>(settlementId),
      'snapshot': serializer.toJson<Object?>(
        $DocumentsTable.$convertersnapshot.toJson(snapshot),
      ),
      'issued_at': serializer.toJson<String?>(issuedAt),
      'issued_by': serializer.toJson<String?>(issuedBy),
      'voided': serializer.toJson<bool>(voided),
      'voided_at': serializer.toJson<String?>(voidedAt),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  DocumentRow copyWith({
    String? businessId,
    String? id,
    String? type,
    String? number,
    String? transactionId,
    Value<String?> settlementId = const Value.absent(),
    Map<String, dynamic>? snapshot,
    Value<String?> issuedAt = const Value.absent(),
    Value<String?> issuedBy = const Value.absent(),
    bool? voided,
    Value<String?> voidedAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
  }) => DocumentRow(
    businessId: businessId ?? this.businessId,
    id: id ?? this.id,
    type: type ?? this.type,
    number: number ?? this.number,
    transactionId: transactionId ?? this.transactionId,
    settlementId: settlementId.present ? settlementId.value : this.settlementId,
    snapshot: snapshot ?? this.snapshot,
    issuedAt: issuedAt.present ? issuedAt.value : this.issuedAt,
    issuedBy: issuedBy.present ? issuedBy.value : this.issuedBy,
    voided: voided ?? this.voided,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      number: data.number.present ? data.number.value : this.number,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      settlementId: data.settlementId.present
          ? data.settlementId.value
          : this.settlementId,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      issuedBy: data.issuedBy.present ? data.issuedBy.value : this.issuedBy,
      voided: data.voided.present ? data.voided.value : this.voided,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('businessId: $businessId, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('number: $number, ')
          ..write('transactionId: $transactionId, ')
          ..write('settlementId: $settlementId, ')
          ..write('snapshot: $snapshot, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedBy: $issuedBy, ')
          ..write('voided: $voided, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    id,
    type,
    number,
    transactionId,
    settlementId,
    snapshot,
    issuedAt,
    issuedBy,
    voided,
    voidedAt,
    updatedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.businessId == this.businessId &&
          other.id == this.id &&
          other.type == this.type &&
          other.number == this.number &&
          other.transactionId == this.transactionId &&
          other.settlementId == this.settlementId &&
          other.snapshot == this.snapshot &&
          other.issuedAt == this.issuedAt &&
          other.issuedBy == this.issuedBy &&
          other.voided == this.voided &&
          other.voidedAt == this.voidedAt &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> businessId;
  final Value<String> id;
  final Value<String> type;
  final Value<String> number;
  final Value<String> transactionId;
  final Value<String?> settlementId;
  final Value<Map<String, dynamic>> snapshot;
  final Value<String?> issuedAt;
  final Value<String?> issuedBy;
  final Value<bool> voided;
  final Value<String?> voidedAt;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.businessId = const Value.absent(),
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.number = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.settlementId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.issuedBy = const Value.absent(),
    this.voided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String businessId,
    required String id,
    this.type = const Value.absent(),
    this.number = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.settlementId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.issuedBy = const Value.absent(),
    this.voided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       id = Value(id);
  static Insertable<DocumentRow> custom({
    Expression<String>? businessId,
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? number,
    Expression<String>? transactionId,
    Expression<String>? settlementId,
    Expression<String>? snapshot,
    Expression<String>? issuedAt,
    Expression<String>? issuedBy,
    Expression<bool>? voided,
    Expression<String>? voidedAt,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (number != null) 'number': number,
      if (transactionId != null) 'transaction_id': transactionId,
      if (settlementId != null) 'settlement_id': settlementId,
      if (snapshot != null) 'snapshot': snapshot,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (issuedBy != null) 'issued_by': issuedBy,
      if (voided != null) 'voided': voided,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? businessId,
    Value<String>? id,
    Value<String>? type,
    Value<String>? number,
    Value<String>? transactionId,
    Value<String?>? settlementId,
    Value<Map<String, dynamic>>? snapshot,
    Value<String?>? issuedAt,
    Value<String?>? issuedBy,
    Value<bool>? voided,
    Value<String?>? voidedAt,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      businessId: businessId ?? this.businessId,
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      transactionId: transactionId ?? this.transactionId,
      settlementId: settlementId ?? this.settlementId,
      snapshot: snapshot ?? this.snapshot,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedBy: issuedBy ?? this.issuedBy,
      voided: voided ?? this.voided,
      voidedAt: voidedAt ?? this.voidedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (settlementId.present) {
      map['settlement_id'] = Variable<String>(settlementId.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(
        $DocumentsTable.$convertersnapshot.toSql(snapshot.value),
      );
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<String>(issuedAt.value);
    }
    if (issuedBy.present) {
      map['issued_by'] = Variable<String>(issuedBy.value);
    }
    if (voided.present) {
      map['voided'] = Variable<bool>(voided.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<String>(voidedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('businessId: $businessId, ')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('number: $number, ')
          ..write('transactionId: $transactionId, ')
          ..write('settlementId: $settlementId, ')
          ..write('snapshot: $snapshot, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedBy: $issuedBy, ')
          ..write('voided: $voided, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog with TableInfo<$AuditLogTable, AuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  before = GeneratedColumn<String>(
    'before',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, dynamic>>($AuditLogTable.$converterbefore);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  after = GeneratedColumn<String>(
    'after',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, dynamic>>($AuditLogTable.$converterafter);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    entity,
    entityId,
    action,
    actor,
    before,
    after,
    note,
    at,
    updatedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      before: $AuditLogTable.$converterbefore.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}before'],
        )!,
      ),
      after: $AuditLogTable.$converterafter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}after'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterbefore = const JsonMapConverter();
  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterafter = const JsonMapConverter();
}

class AuditRow extends DataClass implements Insertable<AuditRow> {
  final int id;
  final String businessId;
  final String entity;
  final String entityId;
  final String action;
  final String actor;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String? note;
  final String? at;
  final String? updatedAt;
  final int seq;
  const AuditRow({
    required this.id,
    required this.businessId,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.actor,
    required this.before,
    required this.after,
    this.note,
    this.at,
    this.updatedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['business_id'] = Variable<String>(businessId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['actor'] = Variable<String>(actor);
    {
      map['before'] = Variable<String>(
        $AuditLogTable.$converterbefore.toSql(before),
      );
    }
    {
      map['after'] = Variable<String>(
        $AuditLogTable.$converterafter.toSql(after),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || at != null) {
      map['at'] = Variable<String>(at);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      businessId: Value(businessId),
      entity: Value(entity),
      entityId: Value(entityId),
      action: Value(action),
      actor: Value(actor),
      before: Value(before),
      after: Value(after),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      at: at == null && nullToAbsent ? const Value.absent() : Value(at),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
    );
  }

  factory AuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditRow(
      id: serializer.fromJson<int>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      action: serializer.fromJson<String>(json['action']),
      actor: serializer.fromJson<String>(json['actor']),
      before: $AuditLogTable.$converterbefore.fromJson(
        serializer.fromJson<Object?>(json['before']),
      ),
      after: $AuditLogTable.$converterafter.fromJson(
        serializer.fromJson<Object?>(json['after']),
      ),
      note: serializer.fromJson<String?>(json['note']),
      at: serializer.fromJson<String?>(json['at']),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'business_id': serializer.toJson<String>(businessId),
      'entity': serializer.toJson<String>(entity),
      'entity_id': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'actor': serializer.toJson<String>(actor),
      'before': serializer.toJson<Object?>(
        $AuditLogTable.$converterbefore.toJson(before),
      ),
      'after': serializer.toJson<Object?>(
        $AuditLogTable.$converterafter.toJson(after),
      ),
      'note': serializer.toJson<String?>(note),
      'at': serializer.toJson<String?>(at),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  AuditRow copyWith({
    int? id,
    String? businessId,
    String? entity,
    String? entityId,
    String? action,
    String? actor,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Value<String?> note = const Value.absent(),
    Value<String?> at = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
  }) => AuditRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    actor: actor ?? this.actor,
    before: before ?? this.before,
    after: after ?? this.after,
    note: note.present ? note.value : this.note,
    at: at.present ? at.value : this.at,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
  );
  AuditRow copyWithCompanion(AuditLogCompanion data) {
    return AuditRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      actor: data.actor.present ? data.actor.value : this.actor,
      before: data.before.present ? data.before.value : this.before,
      after: data.after.present ? data.after.value : this.after,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('actor: $actor, ')
          ..write('before: $before, ')
          ..write('after: $after, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    entity,
    entityId,
    action,
    actor,
    before,
    after,
    note,
    at,
    updatedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.actor == this.actor &&
          other.before == this.before &&
          other.after == this.after &&
          other.note == this.note &&
          other.at == this.at &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq);
}

class AuditLogCompanion extends UpdateCompanion<AuditRow> {
  final Value<int> id;
  final Value<String> businessId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> actor;
  final Value<Map<String, dynamic>> before;
  final Value<Map<String, dynamic>> after;
  final Value<String?> note;
  final Value<String?> at;
  final Value<String?> updatedAt;
  final Value<int> seq;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.actor = const Value.absent(),
    this.before = const Value.absent(),
    this.after = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.actor = const Value.absent(),
    this.before = const Value.absent(),
    this.after = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
  }) : businessId = Value(businessId);
  static Insertable<AuditRow> custom({
    Expression<int>? id,
    Expression<String>? businessId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? actor,
    Expression<String>? before,
    Expression<String>? after,
    Expression<String>? note,
    Expression<String>? at,
    Expression<String>? updatedAt,
    Expression<int>? seq,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (actor != null) 'actor': actor,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
    });
  }

  AuditLogCompanion copyWith({
    Value<int>? id,
    Value<String>? businessId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? actor,
    Value<Map<String, dynamic>>? before,
    Value<Map<String, dynamic>>? after,
    Value<String?>? note,
    Value<String?>? at,
    Value<String?>? updatedAt,
    Value<int>? seq,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      actor: actor ?? this.actor,
      before: before ?? this.before,
      after: after ?? this.after,
      note: note ?? this.note,
      at: at ?? this.at,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (before.present) {
      map['before'] = Variable<String>(
        $AuditLogTable.$converterbefore.toSql(before.value),
      );
    }
    if (after.present) {
      map['after'] = Variable<String>(
        $AuditLogTable.$converterafter.toSql(after.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('actor: $actor, ')
          ..write('before: $before, ')
          ..write('after: $after, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTableTable extends DailyStatsTable
    with TableInfo<$DailyStatsTableTable, DailyStatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomeMinorMeta = const VerificationMeta(
    'incomeMinor',
  );
  @override
  late final GeneratedColumn<int> incomeMinor = GeneratedColumn<int>(
    'income_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _expenseMinorMeta = const VerificationMeta(
    'expenseMinor',
  );
  @override
  late final GeneratedColumn<int> expenseMinor = GeneratedColumn<int>(
    'expense_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashInMinorMeta = const VerificationMeta(
    'cashInMinor',
  );
  @override
  late final GeneratedColumn<int> cashInMinor = GeneratedColumn<int>(
    'cash_in_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashOutMinorMeta = const VerificationMeta(
    'cashOutMinor',
  );
  @override
  late final GeneratedColumn<int> cashOutMinor = GeneratedColumn<int>(
    'cash_out_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  byCategory =
      GeneratedColumn<String>(
        'by_category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $DailyStatsTableTable.$converterbyCategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  byProject =
      GeneratedColumn<String>(
        'by_project',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, dynamic>>(
        $DailyStatsTableTable.$converterbyProject,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  byType = GeneratedColumn<String>(
    'by_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, dynamic>>($DailyStatsTableTable.$converterbyType);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    date,
    incomeMinor,
    expenseMinor,
    cashInMinor,
    cashOutMinor,
    byCategory,
    byProject,
    byType,
    updatedAt,
    seq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStatsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('income_minor')) {
      context.handle(
        _incomeMinorMeta,
        incomeMinor.isAcceptableOrUnknown(
          data['income_minor']!,
          _incomeMinorMeta,
        ),
      );
    }
    if (data.containsKey('expense_minor')) {
      context.handle(
        _expenseMinorMeta,
        expenseMinor.isAcceptableOrUnknown(
          data['expense_minor']!,
          _expenseMinorMeta,
        ),
      );
    }
    if (data.containsKey('cash_in_minor')) {
      context.handle(
        _cashInMinorMeta,
        cashInMinor.isAcceptableOrUnknown(
          data['cash_in_minor']!,
          _cashInMinorMeta,
        ),
      );
    }
    if (data.containsKey('cash_out_minor')) {
      context.handle(
        _cashOutMinorMeta,
        cashOutMinor.isAcceptableOrUnknown(
          data['cash_out_minor']!,
          _cashOutMinorMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, date};
  @override
  DailyStatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStatsRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      incomeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}income_minor'],
      )!,
      expenseMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expense_minor'],
      )!,
      cashInMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_in_minor'],
      )!,
      cashOutMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_out_minor'],
      )!,
      byCategory: $DailyStatsTableTable.$converterbyCategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}by_category'],
        )!,
      ),
      byProject: $DailyStatsTableTable.$converterbyProject.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}by_project'],
        )!,
      ),
      byType: $DailyStatsTableTable.$converterbyType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}by_type'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $DailyStatsTableTable createAlias(String alias) {
    return $DailyStatsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterbyCategory = const JsonMapConverter();
  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterbyProject = const JsonMapConverter();
  static JsonTypeConverter2<Map<String, dynamic>, String, Object?>
  $converterbyType = const JsonMapConverter();
}

class DailyStatsRow extends DataClass implements Insertable<DailyStatsRow> {
  final String businessId;

  /// `yyyy-MM-dd`.
  final String date;
  final int incomeMinor;
  final int expenseMinor;
  final int cashInMinor;
  final int cashOutMinor;
  final Map<String, dynamic> byCategory;
  final Map<String, dynamic> byProject;
  final Map<String, dynamic> byType;
  final String? updatedAt;
  final int seq;
  const DailyStatsRow({
    required this.businessId,
    required this.date,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cashInMinor,
    required this.cashOutMinor,
    required this.byCategory,
    required this.byProject,
    required this.byType,
    this.updatedAt,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['date'] = Variable<String>(date);
    map['income_minor'] = Variable<int>(incomeMinor);
    map['expense_minor'] = Variable<int>(expenseMinor);
    map['cash_in_minor'] = Variable<int>(cashInMinor);
    map['cash_out_minor'] = Variable<int>(cashOutMinor);
    {
      map['by_category'] = Variable<String>(
        $DailyStatsTableTable.$converterbyCategory.toSql(byCategory),
      );
    }
    {
      map['by_project'] = Variable<String>(
        $DailyStatsTableTable.$converterbyProject.toSql(byProject),
      );
    }
    {
      map['by_type'] = Variable<String>(
        $DailyStatsTableTable.$converterbyType.toSql(byType),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['seq'] = Variable<int>(seq);
    return map;
  }

  DailyStatsTableCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsTableCompanion(
      businessId: Value(businessId),
      date: Value(date),
      incomeMinor: Value(incomeMinor),
      expenseMinor: Value(expenseMinor),
      cashInMinor: Value(cashInMinor),
      cashOutMinor: Value(cashOutMinor),
      byCategory: Value(byCategory),
      byProject: Value(byProject),
      byType: Value(byType),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      seq: Value(seq),
    );
  }

  factory DailyStatsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStatsRow(
      businessId: serializer.fromJson<String>(json['business_id']),
      date: serializer.fromJson<String>(json['date']),
      incomeMinor: serializer.fromJson<int>(json['income_minor']),
      expenseMinor: serializer.fromJson<int>(json['expense_minor']),
      cashInMinor: serializer.fromJson<int>(json['cash_in_minor']),
      cashOutMinor: serializer.fromJson<int>(json['cash_out_minor']),
      byCategory: $DailyStatsTableTable.$converterbyCategory.fromJson(
        serializer.fromJson<Object?>(json['by_category']),
      ),
      byProject: $DailyStatsTableTable.$converterbyProject.fromJson(
        serializer.fromJson<Object?>(json['by_project']),
      ),
      byType: $DailyStatsTableTable.$converterbyType.fromJson(
        serializer.fromJson<Object?>(json['by_type']),
      ),
      updatedAt: serializer.fromJson<String?>(json['updated_at']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'date': serializer.toJson<String>(date),
      'income_minor': serializer.toJson<int>(incomeMinor),
      'expense_minor': serializer.toJson<int>(expenseMinor),
      'cash_in_minor': serializer.toJson<int>(cashInMinor),
      'cash_out_minor': serializer.toJson<int>(cashOutMinor),
      'by_category': serializer.toJson<Object?>(
        $DailyStatsTableTable.$converterbyCategory.toJson(byCategory),
      ),
      'by_project': serializer.toJson<Object?>(
        $DailyStatsTableTable.$converterbyProject.toJson(byProject),
      ),
      'by_type': serializer.toJson<Object?>(
        $DailyStatsTableTable.$converterbyType.toJson(byType),
      ),
      'updated_at': serializer.toJson<String?>(updatedAt),
      'seq': serializer.toJson<int>(seq),
    };
  }

  DailyStatsRow copyWith({
    String? businessId,
    String? date,
    int? incomeMinor,
    int? expenseMinor,
    int? cashInMinor,
    int? cashOutMinor,
    Map<String, dynamic>? byCategory,
    Map<String, dynamic>? byProject,
    Map<String, dynamic>? byType,
    Value<String?> updatedAt = const Value.absent(),
    int? seq,
  }) => DailyStatsRow(
    businessId: businessId ?? this.businessId,
    date: date ?? this.date,
    incomeMinor: incomeMinor ?? this.incomeMinor,
    expenseMinor: expenseMinor ?? this.expenseMinor,
    cashInMinor: cashInMinor ?? this.cashInMinor,
    cashOutMinor: cashOutMinor ?? this.cashOutMinor,
    byCategory: byCategory ?? this.byCategory,
    byProject: byProject ?? this.byProject,
    byType: byType ?? this.byType,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    seq: seq ?? this.seq,
  );
  DailyStatsRow copyWithCompanion(DailyStatsTableCompanion data) {
    return DailyStatsRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      date: data.date.present ? data.date.value : this.date,
      incomeMinor: data.incomeMinor.present
          ? data.incomeMinor.value
          : this.incomeMinor,
      expenseMinor: data.expenseMinor.present
          ? data.expenseMinor.value
          : this.expenseMinor,
      cashInMinor: data.cashInMinor.present
          ? data.cashInMinor.value
          : this.cashInMinor,
      cashOutMinor: data.cashOutMinor.present
          ? data.cashOutMinor.value
          : this.cashOutMinor,
      byCategory: data.byCategory.present
          ? data.byCategory.value
          : this.byCategory,
      byProject: data.byProject.present ? data.byProject.value : this.byProject,
      byType: data.byType.present ? data.byType.value : this.byType,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsRow(')
          ..write('businessId: $businessId, ')
          ..write('date: $date, ')
          ..write('incomeMinor: $incomeMinor, ')
          ..write('expenseMinor: $expenseMinor, ')
          ..write('cashInMinor: $cashInMinor, ')
          ..write('cashOutMinor: $cashOutMinor, ')
          ..write('byCategory: $byCategory, ')
          ..write('byProject: $byProject, ')
          ..write('byType: $byType, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    date,
    incomeMinor,
    expenseMinor,
    cashInMinor,
    cashOutMinor,
    byCategory,
    byProject,
    byType,
    updatedAt,
    seq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStatsRow &&
          other.businessId == this.businessId &&
          other.date == this.date &&
          other.incomeMinor == this.incomeMinor &&
          other.expenseMinor == this.expenseMinor &&
          other.cashInMinor == this.cashInMinor &&
          other.cashOutMinor == this.cashOutMinor &&
          other.byCategory == this.byCategory &&
          other.byProject == this.byProject &&
          other.byType == this.byType &&
          other.updatedAt == this.updatedAt &&
          other.seq == this.seq);
}

class DailyStatsTableCompanion extends UpdateCompanion<DailyStatsRow> {
  final Value<String> businessId;
  final Value<String> date;
  final Value<int> incomeMinor;
  final Value<int> expenseMinor;
  final Value<int> cashInMinor;
  final Value<int> cashOutMinor;
  final Value<Map<String, dynamic>> byCategory;
  final Value<Map<String, dynamic>> byProject;
  final Value<Map<String, dynamic>> byType;
  final Value<String?> updatedAt;
  final Value<int> seq;
  final Value<int> rowid;
  const DailyStatsTableCompanion({
    this.businessId = const Value.absent(),
    this.date = const Value.absent(),
    this.incomeMinor = const Value.absent(),
    this.expenseMinor = const Value.absent(),
    this.cashInMinor = const Value.absent(),
    this.cashOutMinor = const Value.absent(),
    this.byCategory = const Value.absent(),
    this.byProject = const Value.absent(),
    this.byType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStatsTableCompanion.insert({
    required String businessId,
    required String date,
    this.incomeMinor = const Value.absent(),
    this.expenseMinor = const Value.absent(),
    this.cashInMinor = const Value.absent(),
    this.cashOutMinor = const Value.absent(),
    this.byCategory = const Value.absent(),
    this.byProject = const Value.absent(),
    this.byType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       date = Value(date);
  static Insertable<DailyStatsRow> custom({
    Expression<String>? businessId,
    Expression<String>? date,
    Expression<int>? incomeMinor,
    Expression<int>? expenseMinor,
    Expression<int>? cashInMinor,
    Expression<int>? cashOutMinor,
    Expression<String>? byCategory,
    Expression<String>? byProject,
    Expression<String>? byType,
    Expression<String>? updatedAt,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (date != null) 'date': date,
      if (incomeMinor != null) 'income_minor': incomeMinor,
      if (expenseMinor != null) 'expense_minor': expenseMinor,
      if (cashInMinor != null) 'cash_in_minor': cashInMinor,
      if (cashOutMinor != null) 'cash_out_minor': cashOutMinor,
      if (byCategory != null) 'by_category': byCategory,
      if (byProject != null) 'by_project': byProject,
      if (byType != null) 'by_type': byType,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStatsTableCompanion copyWith({
    Value<String>? businessId,
    Value<String>? date,
    Value<int>? incomeMinor,
    Value<int>? expenseMinor,
    Value<int>? cashInMinor,
    Value<int>? cashOutMinor,
    Value<Map<String, dynamic>>? byCategory,
    Value<Map<String, dynamic>>? byProject,
    Value<Map<String, dynamic>>? byType,
    Value<String?>? updatedAt,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return DailyStatsTableCompanion(
      businessId: businessId ?? this.businessId,
      date: date ?? this.date,
      incomeMinor: incomeMinor ?? this.incomeMinor,
      expenseMinor: expenseMinor ?? this.expenseMinor,
      cashInMinor: cashInMinor ?? this.cashInMinor,
      cashOutMinor: cashOutMinor ?? this.cashOutMinor,
      byCategory: byCategory ?? this.byCategory,
      byProject: byProject ?? this.byProject,
      byType: byType ?? this.byType,
      updatedAt: updatedAt ?? this.updatedAt,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (incomeMinor.present) {
      map['income_minor'] = Variable<int>(incomeMinor.value);
    }
    if (expenseMinor.present) {
      map['expense_minor'] = Variable<int>(expenseMinor.value);
    }
    if (cashInMinor.present) {
      map['cash_in_minor'] = Variable<int>(cashInMinor.value);
    }
    if (cashOutMinor.present) {
      map['cash_out_minor'] = Variable<int>(cashOutMinor.value);
    }
    if (byCategory.present) {
      map['by_category'] = Variable<String>(
        $DailyStatsTableTable.$converterbyCategory.toSql(byCategory.value),
      );
    }
    if (byProject.present) {
      map['by_project'] = Variable<String>(
        $DailyStatsTableTable.$converterbyProject.toSql(byProject.value),
      );
    }
    if (byType.present) {
      map['by_type'] = Variable<String>(
        $DailyStatsTableTable.$converterbyType.toSql(byType.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsTableCompanion(')
          ..write('businessId: $businessId, ')
          ..write('date: $date, ')
          ..write('incomeMinor: $incomeMinor, ')
          ..write('expenseMinor: $expenseMinor, ')
          ..write('cashInMinor: $cashInMinor, ')
          ..write('cashOutMinor: $cashOutMinor, ')
          ..write('byCategory: $byCategory, ')
          ..write('byProject: $byProject, ')
          ..write('byType: $byType, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableKeyMeta = const VerificationMeta(
    'tableKey',
  );
  @override
  late final GeneratedColumn<String> tableKey = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [businessId, tableKey, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _tableKeyMeta,
        tableKey.isAcceptableOrUnknown(data['table_name']!, _tableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_tableKeyMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, tableKey};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      tableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String businessId;
  final String tableKey;
  final int seq;
  const SyncCursorRow({
    required this.businessId,
    required this.tableKey,
    required this.seq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['table_name'] = Variable<String>(tableKey);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      businessId: Value(businessId),
      tableKey: Value(tableKey),
      seq: Value(seq),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      businessId: serializer.fromJson<String>(json['business_id']),
      tableKey: serializer.fromJson<String>(json['table_name']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'table_name': serializer.toJson<String>(tableKey),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncCursorRow copyWith({String? businessId, String? tableKey, int? seq}) =>
      SyncCursorRow(
        businessId: businessId ?? this.businessId,
        tableKey: tableKey ?? this.tableKey,
        seq: seq ?? this.seq,
      );
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      tableKey: data.tableKey.present ? data.tableKey.value : this.tableKey,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('businessId: $businessId, ')
          ..write('tableKey: $tableKey, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(businessId, tableKey, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.businessId == this.businessId &&
          other.tableKey == this.tableKey &&
          other.seq == this.seq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> businessId;
  final Value<String> tableKey;
  final Value<int> seq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.businessId = const Value.absent(),
    this.tableKey = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String businessId,
    required String tableKey,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       tableKey = Value(tableKey);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? businessId,
    Expression<String>? tableKey,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (tableKey != null) 'table_name': tableKey,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? businessId,
    Value<String>? tableKey,
    Value<int>? seq,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      businessId: businessId ?? this.businessId,
      tableKey: tableKey ?? this.tableKey,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (tableKey.present) {
      map['table_name'] = Variable<String>(tableKey.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('businessId: $businessId, ')
          ..write('tableKey: $tableKey, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMetaTable extends LocalMeta
    with TableInfo<$LocalMetaTable, LocalMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalMetaTable createAlias(String alias) {
    return $LocalMetaTable(attachedDatabase, alias);
  }
}

class LocalMetaRow extends DataClass implements Insertable<LocalMetaRow> {
  final String key;
  final String value;
  const LocalMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalMetaCompanion(key: Value(key), value: Value(value));
  }

  factory LocalMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalMetaRow copyWith({String? key, String? value}) =>
      LocalMetaRow(key: key ?? this.key, value: value ?? this.value);
  LocalMetaRow copyWithCompanion(LocalMetaCompanion data) {
    return LocalMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalMetaCompanion extends UpdateCompanion<LocalMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $BusinessesTable businesses = $BusinessesTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CustomFieldsTable customFields = $CustomFieldsTable(this);
  late final $PartiesTable parties = $PartiesTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SettlementsTable settlements = $SettlementsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DailyStatsTableTable dailyStatsTable = $DailyStatsTableTable(
    this,
  );
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $LocalMetaTable localMeta = $LocalMetaTable(this);
  late final Index membersUserIdx = Index(
    'members_user_idx',
    'CREATE INDEX members_user_idx ON members (user_id)',
  );
  late final Index categoriesBusinessIdx = Index(
    'categories_business_idx',
    'CREATE INDEX categories_business_idx ON categories (business_id)',
  );
  late final Index customFieldsBusinessIdx = Index(
    'custom_fields_business_idx',
    'CREATE INDEX custom_fields_business_idx ON custom_fields (business_id)',
  );
  late final Index partiesBusinessIdx = Index(
    'parties_business_idx',
    'CREATE INDEX parties_business_idx ON parties (business_id)',
  );
  late final Index projectsBusinessIdx = Index(
    'projects_business_idx',
    'CREATE INDEX projects_business_idx ON projects (business_id)',
  );
  late final Index transactionsDateIdx = Index(
    'transactions_date_idx',
    'CREATE INDEX transactions_date_idx ON transactions (business_id, date)',
  );
  late final Index transactionsOpenIdx = Index(
    'transactions_open_idx',
    'CREATE INDEX transactions_open_idx ON transactions (business_id, is_open)',
  );
  late final Index transactionsLinkedIdx = Index(
    'transactions_linked_idx',
    'CREATE INDEX transactions_linked_idx ON transactions (linked_transaction_id)',
  );
  late final Index settlementsBusinessIdx = Index(
    'settlements_business_idx',
    'CREATE INDEX settlements_business_idx ON settlements (business_id)',
  );
  late final Index documentsTransactionIdx = Index(
    'documents_transaction_idx',
    'CREATE INDEX documents_transaction_idx ON documents (transaction_id)',
  );
  late final Index auditEntityIdx = Index(
    'audit_entity_idx',
    'CREATE INDEX audit_entity_idx ON audit_log (business_id, entity_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    businesses,
    members,
    categories,
    customFields,
    parties,
    projects,
    transactions,
    settlements,
    documents,
    auditLog,
    dailyStatsTable,
    syncCursors,
    localMeta,
    membersUserIdx,
    categoriesBusinessIdx,
    customFieldsBusinessIdx,
    partiesBusinessIdx,
    projectsBusinessIdx,
    transactionsDateIdx,
    transactionsOpenIdx,
    transactionsLinkedIdx,
    settlementsBusinessIdx,
    documentsTransactionIdx,
    auditEntityIdx,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      Value<String> email,
      Value<String> displayName,
      Value<String> photoUrl,
      Value<String?> lastBusinessId,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> displayName,
      Value<String> photoUrl,
      Value<String?> lastBusinessId,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastBusinessId => $composableBuilder(
    column: $table.lastBusinessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastBusinessId => $composableBuilder(
    column: $table.lastBusinessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get lastBusinessId => $composableBuilder(
    column: $table.lastBusinessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<String?> lastBusinessId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                email: email,
                displayName: displayName,
                photoUrl: photoUrl,
                lastBusinessId: lastBusinessId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<String?> lastBusinessId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                email: email,
                displayName: displayName,
                photoUrl: photoUrl,
                lastBusinessId: lastBusinessId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$BusinessesTableCreateCompanionBuilder =
    BusinessesCompanion Function({
      required String id,
      Value<String> name,
      Value<String> description,
      Value<String> currencyCode,
      Value<int> currencyDecimals,
      Value<String> currencySymbol,
      Value<String> timezone,
      Value<String> template,
      Value<String> ownerId,
      Value<Map<String, dynamic>> settings,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$BusinessesTableUpdateCompanionBuilder =
    BusinessesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<String> currencyCode,
      Value<int> currencyDecimals,
      Value<String> currencySymbol,
      Value<String> timezone,
      Value<String> template,
      Value<String> ownerId,
      Value<Map<String, dynamic>> settings,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$BusinessesTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currencyDecimals => $composableBuilder(
    column: $table.currencyDecimals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currencyDecimals => $composableBuilder(
    column: $table.currencyDecimals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currencyDecimals => $composableBuilder(
    column: $table.currencyDecimals,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$BusinessesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessesTable,
          BusinessRow,
          $$BusinessesTableFilterComposer,
          $$BusinessesTableOrderingComposer,
          $$BusinessesTableAnnotationComposer,
          $$BusinessesTableCreateCompanionBuilder,
          $$BusinessesTableUpdateCompanionBuilder,
          (
            BusinessRow,
            BaseReferences<_$AppDatabase, $BusinessesTable, BusinessRow>,
          ),
          BusinessRow,
          PrefetchHooks Function()
        > {
  $$BusinessesTableTableManager(_$AppDatabase db, $BusinessesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> currencyDecimals = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<Map<String, dynamic>> settings = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesCompanion(
                id: id,
                name: name,
                description: description,
                currencyCode: currencyCode,
                currencyDecimals: currencyDecimals,
                currencySymbol: currencySymbol,
                timezone: timezone,
                template: template,
                ownerId: ownerId,
                settings: settings,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> currencyDecimals = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<Map<String, dynamic>> settings = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesCompanion.insert(
                id: id,
                name: name,
                description: description,
                currencyCode: currencyCode,
                currencyDecimals: currencyDecimals,
                currencySymbol: currencySymbol,
                timezone: timezone,
                template: template,
                ownerId: ownerId,
                settings: settings,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessesTable,
      BusinessRow,
      $$BusinessesTableFilterComposer,
      $$BusinessesTableOrderingComposer,
      $$BusinessesTableAnnotationComposer,
      $$BusinessesTableCreateCompanionBuilder,
      $$BusinessesTableUpdateCompanionBuilder,
      (
        BusinessRow,
        BaseReferences<_$AppDatabase, $BusinessesTable, BusinessRow>,
      ),
      BusinessRow,
      PrefetchHooks Function()
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String businessId,
      required String userId,
      Value<String> role,
      Value<String> email,
      Value<String> displayName,
      Value<String> photoUrl,
      Value<String?> addedBy,
      Value<String?> addedAt,
      Value<String?> updatedAt,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> businessId,
      Value<String> userId,
      Value<String> role,
      Value<String> email,
      Value<String> displayName,
      Value<String> photoUrl,
      Value<String?> addedBy,
      Value<String?> addedAt,
      Value<String?> updatedAt,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<int> rowid,
    });

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get addedBy =>
      $composableBuilder(column: $table.addedBy, builder: (column) => column);

  GeneratedColumn<String> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
          MemberRow,
          PrefetchHooks Function()
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<String?> addedBy = const Value.absent(),
                Value<String?> addedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                businessId: businessId,
                userId: userId,
                role: role,
                email: email,
                displayName: displayName,
                photoUrl: photoUrl,
                addedBy: addedBy,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String userId,
                Value<String> role = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> photoUrl = const Value.absent(),
                Value<String?> addedBy = const Value.absent(),
                Value<String?> addedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                businessId: businessId,
                userId: userId,
                role: role,
                email: email,
                displayName: displayName,
                photoUrl: photoUrl,
                addedBy: addedBy,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
      MemberRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String businessId,
      Value<String> name,
      Value<String> kind,
      Value<String> icon,
      Value<String> colour,
      Value<List<dynamic>> fieldIds,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> kind,
      Value<String> icon,
      Value<String> colour,
      Value<List<dynamic>> fieldIds,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
  get fieldIds => $composableBuilder(
    column: $table.fieldIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldIds => $composableBuilder(
    column: $table.fieldIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get fieldIds =>
      $composableBuilder(column: $table.fieldIds, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> colour = const Value.absent(),
                Value<List<dynamic>> fieldIds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                kind: kind,
                icon: icon,
                colour: colour,
                fieldIds: fieldIds,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> colour = const Value.absent(),
                Value<List<dynamic>> fieldIds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                kind: kind,
                icon: icon,
                colour: colour,
                fieldIds: fieldIds,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$CustomFieldsTableCreateCompanionBuilder =
    CustomFieldsCompanion Function({
      required String id,
      required String businessId,
      Value<String> label,
      Value<String> type,
      Value<List<dynamic>> options,
      Value<bool> required,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$CustomFieldsTableUpdateCompanionBuilder =
    CustomFieldsCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> label,
      Value<String> type,
      Value<List<dynamic>> options,
      Value<bool> required,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$CustomFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
  get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFieldsTable> {
  $$CustomFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$CustomFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomFieldsTable,
          CustomFieldRow,
          $$CustomFieldsTableFilterComposer,
          $$CustomFieldsTableOrderingComposer,
          $$CustomFieldsTableAnnotationComposer,
          $$CustomFieldsTableCreateCompanionBuilder,
          $$CustomFieldsTableUpdateCompanionBuilder,
          (
            CustomFieldRow,
            BaseReferences<_$AppDatabase, $CustomFieldsTable, CustomFieldRow>,
          ),
          CustomFieldRow,
          PrefetchHooks Function()
        > {
  $$CustomFieldsTableTableManager(_$AppDatabase db, $CustomFieldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<List<dynamic>> options = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomFieldsCompanion(
                id: id,
                businessId: businessId,
                label: label,
                type: type,
                options: options,
                required: required,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> label = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<List<dynamic>> options = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomFieldsCompanion.insert(
                id: id,
                businessId: businessId,
                label: label,
                type: type,
                options: options,
                required: required,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomFieldsTable,
      CustomFieldRow,
      $$CustomFieldsTableFilterComposer,
      $$CustomFieldsTableOrderingComposer,
      $$CustomFieldsTableAnnotationComposer,
      $$CustomFieldsTableCreateCompanionBuilder,
      $$CustomFieldsTableUpdateCompanionBuilder,
      (
        CustomFieldRow,
        BaseReferences<_$AppDatabase, $CustomFieldsTable, CustomFieldRow>,
      ),
      CustomFieldRow,
      PrefetchHooks Function()
    >;
typedef $$PartiesTableCreateCompanionBuilder =
    PartiesCompanion Function({
      required String id,
      required String businessId,
      Value<String> name,
      Value<String> kind,
      Value<String> phone,
      Value<String> email,
      Value<String> address,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$PartiesTableUpdateCompanionBuilder =
    PartiesCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> kind,
      Value<String> phone,
      Value<String> email,
      Value<String> address,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$PartiesTableFilterComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PartiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PartiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartiesTable> {
  $$PartiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$PartiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PartiesTable,
          PartyRow,
          $$PartiesTableFilterComposer,
          $$PartiesTableOrderingComposer,
          $$PartiesTableAnnotationComposer,
          $$PartiesTableCreateCompanionBuilder,
          $$PartiesTableUpdateCompanionBuilder,
          (PartyRow, BaseReferences<_$AppDatabase, $PartiesTable, PartyRow>),
          PartyRow,
          PrefetchHooks Function()
        > {
  $$PartiesTableTableManager(_$AppDatabase db, $PartiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                kind: kind,
                phone: phone,
                email: email,
                address: address,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PartiesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                kind: kind,
                phone: phone,
                email: email,
                address: address,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PartiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PartiesTable,
      PartyRow,
      $$PartiesTableFilterComposer,
      $$PartiesTableOrderingComposer,
      $$PartiesTableAnnotationComposer,
      $$PartiesTableCreateCompanionBuilder,
      $$PartiesTableUpdateCompanionBuilder,
      (PartyRow, BaseReferences<_$AppDatabase, $PartiesTable, PartyRow>),
      PartyRow,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required String businessId,
      Value<String> name,
      Value<String> code,
      Value<String> description,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String> code,
      Value<String> description,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectRow,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (
            ProjectRow,
            BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>,
          ),
          ProjectRow,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                businessId: businessId,
                name: name,
                code: code,
                description: description,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                code: code,
                description: description,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectRow,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRow, BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow>),
      ProjectRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String businessId,
      Value<String> type,
      Value<String?> direction,
      Value<String> status,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<String?> partyId,
      Value<String?> partyName,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<String> description,
      Value<String> reference,
      Value<String> notes,
      Value<String> paymentMethod,
      Value<String?> date,
      Value<String?> dueDate,
      Value<String?> receiptDate,
      Value<List<dynamic>> lineItems,
      Value<int> totalMinor,
      Value<int> paidMinor,
      Value<int> refundedMinor,
      Value<int> creditedMinor,
      Value<int> effectiveMinor,
      Value<int> outstandingMinor,
      Value<String?> paymentStatus,
      Value<bool> isOpen,
      Value<Map<String, dynamic>> customFields,
      Value<String?> linkedTransactionId,
      Value<String?> linkKind,
      Value<String?> settlementId,
      Value<List<dynamic>> searchTokens,
      Value<int> version,
      Value<String> createdBy,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> updatedBy,
      Value<String?> confirmedAt,
      Value<String?> confirmedBy,
      Value<String?> cancelledAt,
      Value<String?> cancelledBy,
      Value<String?> cancelReason,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> type,
      Value<String?> direction,
      Value<String> status,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<String?> partyId,
      Value<String?> partyName,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<String> description,
      Value<String> reference,
      Value<String> notes,
      Value<String> paymentMethod,
      Value<String?> date,
      Value<String?> dueDate,
      Value<String?> receiptDate,
      Value<List<dynamic>> lineItems,
      Value<int> totalMinor,
      Value<int> paidMinor,
      Value<int> refundedMinor,
      Value<int> creditedMinor,
      Value<int> effectiveMinor,
      Value<int> outstandingMinor,
      Value<String?> paymentStatus,
      Value<bool> isOpen,
      Value<Map<String, dynamic>> customFields,
      Value<String?> linkedTransactionId,
      Value<String?> linkKind,
      Value<String?> settlementId,
      Value<List<dynamic>> searchTokens,
      Value<int> version,
      Value<String> createdBy,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String?> updatedBy,
      Value<String?> confirmedAt,
      Value<String?> confirmedBy,
      Value<String?> cancelledAt,
      Value<String?> cancelledBy,
      Value<String?> cancelReason,
      Value<String?> deletedAt,
      Value<int> seq,
      Value<bool> localPending,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyId => $composableBuilder(
    column: $table.partyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
  get lineItems => $composableBuilder(
    column: $table.lineItems,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidMinor => $composableBuilder(
    column: $table.paidMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundedMinor => $composableBuilder(
    column: $table.refundedMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditedMinor => $composableBuilder(
    column: $table.creditedMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveMinor => $composableBuilder(
    column: $table.effectiveMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outstandingMinor => $composableBuilder(
    column: $table.outstandingMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOpen => $composableBuilder(
    column: $table.isOpen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkKind => $composableBuilder(
    column: $table.linkKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<dynamic>, List<dynamic>, String>
  get searchTokens => $composableBuilder(
    column: $table.searchTokens,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyId => $composableBuilder(
    column: $table.partyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineItems => $composableBuilder(
    column: $table.lineItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidMinor => $composableBuilder(
    column: $table.paidMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundedMinor => $composableBuilder(
    column: $table.refundedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditedMinor => $composableBuilder(
    column: $table.creditedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveMinor => $composableBuilder(
    column: $table.effectiveMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outstandingMinor => $composableBuilder(
    column: $table.outstandingMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOpen => $composableBuilder(
    column: $table.isOpen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkKind => $composableBuilder(
    column: $table.linkKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchTokens => $composableBuilder(
    column: $table.searchTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyId =>
      $composableBuilder(column: $table.partyId, builder: (column) => column);

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get lineItems =>
      $composableBuilder(column: $table.lineItems, builder: (column) => column);

  GeneratedColumn<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidMinor =>
      $composableBuilder(column: $table.paidMinor, builder: (column) => column);

  GeneratedColumn<int> get refundedMinor => $composableBuilder(
    column: $table.refundedMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditedMinor => $composableBuilder(
    column: $table.creditedMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get effectiveMinor => $composableBuilder(
    column: $table.effectiveMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outstandingMinor => $composableBuilder(
    column: $table.outstandingMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOpen =>
      $composableBuilder(column: $table.isOpen, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkKind =>
      $composableBuilder(column: $table.linkKind, builder: (column) => column);

  GeneratedColumn<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<dynamic>, String> get searchTokens =>
      $composableBuilder(
        column: $table.searchTokens,
        builder: (column) => column,
      );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelledBy => $composableBuilder(
    column: $table.cancelledBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<bool> get localPending => $composableBuilder(
    column: $table.localPending,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRowData,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRowData,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTable,
              TransactionRowData
            >,
          ),
          TransactionRowData,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> direction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> partyId = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> receiptDate = const Value.absent(),
                Value<List<dynamic>> lineItems = const Value.absent(),
                Value<int> totalMinor = const Value.absent(),
                Value<int> paidMinor = const Value.absent(),
                Value<int> refundedMinor = const Value.absent(),
                Value<int> creditedMinor = const Value.absent(),
                Value<int> effectiveMinor = const Value.absent(),
                Value<int> outstandingMinor = const Value.absent(),
                Value<String?> paymentStatus = const Value.absent(),
                Value<bool> isOpen = const Value.absent(),
                Value<Map<String, dynamic>> customFields = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<String?> linkKind = const Value.absent(),
                Value<String?> settlementId = const Value.absent(),
                Value<List<dynamic>> searchTokens = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> confirmedAt = const Value.absent(),
                Value<String?> confirmedBy = const Value.absent(),
                Value<String?> cancelledAt = const Value.absent(),
                Value<String?> cancelledBy = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                businessId: businessId,
                type: type,
                direction: direction,
                status: status,
                categoryId: categoryId,
                categoryName: categoryName,
                partyId: partyId,
                partyName: partyName,
                projectId: projectId,
                projectName: projectName,
                description: description,
                reference: reference,
                notes: notes,
                paymentMethod: paymentMethod,
                date: date,
                dueDate: dueDate,
                receiptDate: receiptDate,
                lineItems: lineItems,
                totalMinor: totalMinor,
                paidMinor: paidMinor,
                refundedMinor: refundedMinor,
                creditedMinor: creditedMinor,
                effectiveMinor: effectiveMinor,
                outstandingMinor: outstandingMinor,
                paymentStatus: paymentStatus,
                isOpen: isOpen,
                customFields: customFields,
                linkedTransactionId: linkedTransactionId,
                linkKind: linkKind,
                settlementId: settlementId,
                searchTokens: searchTokens,
                version: version,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                confirmedAt: confirmedAt,
                confirmedBy: confirmedBy,
                cancelledAt: cancelledAt,
                cancelledBy: cancelledBy,
                cancelReason: cancelReason,
                deletedAt: deletedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> type = const Value.absent(),
                Value<String?> direction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> partyId = const Value.absent(),
                Value<String?> partyName = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> receiptDate = const Value.absent(),
                Value<List<dynamic>> lineItems = const Value.absent(),
                Value<int> totalMinor = const Value.absent(),
                Value<int> paidMinor = const Value.absent(),
                Value<int> refundedMinor = const Value.absent(),
                Value<int> creditedMinor = const Value.absent(),
                Value<int> effectiveMinor = const Value.absent(),
                Value<int> outstandingMinor = const Value.absent(),
                Value<String?> paymentStatus = const Value.absent(),
                Value<bool> isOpen = const Value.absent(),
                Value<Map<String, dynamic>> customFields = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<String?> linkKind = const Value.absent(),
                Value<String?> settlementId = const Value.absent(),
                Value<List<dynamic>> searchTokens = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> confirmedAt = const Value.absent(),
                Value<String?> confirmedBy = const Value.absent(),
                Value<String?> cancelledAt = const Value.absent(),
                Value<String?> cancelledBy = const Value.absent(),
                Value<String?> cancelReason = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<bool> localPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                businessId: businessId,
                type: type,
                direction: direction,
                status: status,
                categoryId: categoryId,
                categoryName: categoryName,
                partyId: partyId,
                partyName: partyName,
                projectId: projectId,
                projectName: projectName,
                description: description,
                reference: reference,
                notes: notes,
                paymentMethod: paymentMethod,
                date: date,
                dueDate: dueDate,
                receiptDate: receiptDate,
                lineItems: lineItems,
                totalMinor: totalMinor,
                paidMinor: paidMinor,
                refundedMinor: refundedMinor,
                creditedMinor: creditedMinor,
                effectiveMinor: effectiveMinor,
                outstandingMinor: outstandingMinor,
                paymentStatus: paymentStatus,
                isOpen: isOpen,
                customFields: customFields,
                linkedTransactionId: linkedTransactionId,
                linkKind: linkKind,
                settlementId: settlementId,
                searchTokens: searchTokens,
                version: version,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                confirmedAt: confirmedAt,
                confirmedBy: confirmedBy,
                cancelledAt: cancelledAt,
                cancelledBy: cancelledBy,
                cancelReason: cancelReason,
                deletedAt: deletedAt,
                seq: seq,
                localPending: localPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRowData,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRowData,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRowData>,
      ),
      TransactionRowData,
      PrefetchHooks Function()
    >;
typedef $$SettlementsTableCreateCompanionBuilder =
    SettlementsCompanion Function({
      required String businessId,
      required String transactionId,
      required String id,
      Value<String> kind,
      Value<int> amountMinor,
      Value<String> date,
      Value<String> method,
      Value<String> note,
      Value<Map<String, dynamic>> balanceAfter,
      Value<String?> linkedTransactionId,
      Value<String> createdBy,
      Value<String?> createdAt,
      Value<bool> voided,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$SettlementsTableUpdateCompanionBuilder =
    SettlementsCompanion Function({
      Value<String> businessId,
      Value<String> transactionId,
      Value<String> id,
      Value<String> kind,
      Value<int> amountMinor,
      Value<String> date,
      Value<String> method,
      Value<String> note,
      Value<Map<String, dynamic>> balanceAfter,
      Value<String?> linkedTransactionId,
      Value<String> createdBy,
      Value<String?> createdAt,
      Value<bool> voided,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });

class $$SettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get voided =>
      $composableBuilder(column: $table.voided, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettlementsTable,
          SettlementRow,
          $$SettlementsTableFilterComposer,
          $$SettlementsTableOrderingComposer,
          $$SettlementsTableAnnotationComposer,
          $$SettlementsTableCreateCompanionBuilder,
          $$SettlementsTableUpdateCompanionBuilder,
          (
            SettlementRow,
            BaseReferences<_$AppDatabase, $SettlementsTable, SettlementRow>,
          ),
          SettlementRow,
          PrefetchHooks Function()
        > {
  $$SettlementsTableTableManager(_$AppDatabase db, $SettlementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<Map<String, dynamic>> balanceAfter = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion(
                businessId: businessId,
                transactionId: transactionId,
                id: id,
                kind: kind,
                amountMinor: amountMinor,
                date: date,
                method: method,
                note: note,
                balanceAfter: balanceAfter,
                linkedTransactionId: linkedTransactionId,
                createdBy: createdBy,
                createdAt: createdAt,
                voided: voided,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String transactionId,
                required String id,
                Value<String> kind = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<Map<String, dynamic>> balanceAfter = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion.insert(
                businessId: businessId,
                transactionId: transactionId,
                id: id,
                kind: kind,
                amountMinor: amountMinor,
                date: date,
                method: method,
                note: note,
                balanceAfter: balanceAfter,
                linkedTransactionId: linkedTransactionId,
                createdBy: createdBy,
                createdAt: createdAt,
                voided: voided,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettlementsTable,
      SettlementRow,
      $$SettlementsTableFilterComposer,
      $$SettlementsTableOrderingComposer,
      $$SettlementsTableAnnotationComposer,
      $$SettlementsTableCreateCompanionBuilder,
      $$SettlementsTableUpdateCompanionBuilder,
      (
        SettlementRow,
        BaseReferences<_$AppDatabase, $SettlementsTable, SettlementRow>,
      ),
      SettlementRow,
      PrefetchHooks Function()
    >;
typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String businessId,
      required String id,
      Value<String> type,
      Value<String> number,
      Value<String> transactionId,
      Value<String?> settlementId,
      Value<Map<String, dynamic>> snapshot,
      Value<String?> issuedAt,
      Value<String?> issuedBy,
      Value<bool> voided,
      Value<String?> voidedAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> businessId,
      Value<String> id,
      Value<String> type,
      Value<String> number,
      Value<String> transactionId,
      Value<String?> settlementId,
      Value<Map<String, dynamic>> snapshot,
      Value<String?> issuedAt,
      Value<String?> issuedBy,
      Value<bool> voided,
      Value<String?> voidedAt,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuedBy => $composableBuilder(
    column: $table.issuedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuedBy => $composableBuilder(
    column: $table.issuedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settlementId => $composableBuilder(
    column: $table.settlementId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<String> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<String> get issuedBy =>
      $composableBuilder(column: $table.issuedBy, builder: (column) => column);

  GeneratedColumn<bool> get voided =>
      $composableBuilder(column: $table.voided, builder: (column) => column);

  GeneratedColumn<String> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (
            DocumentRow,
            BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
          ),
          DocumentRow,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String?> settlementId = const Value.absent(),
                Value<Map<String, dynamic>> snapshot = const Value.absent(),
                Value<String?> issuedAt = const Value.absent(),
                Value<String?> issuedBy = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                Value<String?> voidedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                businessId: businessId,
                id: id,
                type: type,
                number: number,
                transactionId: transactionId,
                settlementId: settlementId,
                snapshot: snapshot,
                issuedAt: issuedAt,
                issuedBy: issuedBy,
                voided: voided,
                voidedAt: voidedAt,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String id,
                Value<String> type = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String?> settlementId = const Value.absent(),
                Value<Map<String, dynamic>> snapshot = const Value.absent(),
                Value<String?> issuedAt = const Value.absent(),
                Value<String?> issuedBy = const Value.absent(),
                Value<bool> voided = const Value.absent(),
                Value<String?> voidedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                businessId: businessId,
                id: id,
                type: type,
                number: number,
                transactionId: transactionId,
                settlementId: settlementId,
                snapshot: snapshot,
                issuedAt: issuedAt,
                issuedBy: issuedBy,
                voided: voided,
                voidedAt: voidedAt,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (
        DocumentRow,
        BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
      ),
      DocumentRow,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder =
    AuditLogCompanion Function({
      Value<int> id,
      required String businessId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> action,
      Value<String> actor,
      Value<Map<String, dynamic>> before,
      Value<Map<String, dynamic>> after,
      Value<String?> note,
      Value<String?> at,
      Value<String?> updatedAt,
      Value<int> seq,
    });
typedef $$AuditLogTableUpdateCompanionBuilder =
    AuditLogCompanion Function({
      Value<int> id,
      Value<String> businessId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> action,
      Value<String> actor,
      Value<Map<String, dynamic>> before,
      Value<Map<String, dynamic>> after,
      Value<String?> note,
      Value<String?> at,
      Value<String?> updatedAt,
      Value<int> seq,
    });

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get before => $composableBuilder(
    column: $table.before,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get before => $composableBuilder(
    column: $table.before,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get after => $composableBuilder(
    column: $table.after,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get before =>
      $composableBuilder(column: $table.before, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get after =>
      $composableBuilder(column: $table.after, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
          AuditRow,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<Map<String, dynamic>> before = const Value.absent(),
                Value<Map<String, dynamic>> after = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> at = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                businessId: businessId,
                entity: entity,
                entityId: entityId,
                action: action,
                actor: actor,
                before: before,
                after: after,
                note: note,
                at: at,
                updatedAt: updatedAt,
                seq: seq,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String businessId,
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<Map<String, dynamic>> before = const Value.absent(),
                Value<Map<String, dynamic>> after = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> at = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                businessId: businessId,
                entity: entity,
                entityId: entityId,
                action: action,
                actor: actor,
                before: before,
                after: after,
                note: note,
                at: at,
                updatedAt: updatedAt,
                seq: seq,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
      AuditRow,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableTableCreateCompanionBuilder =
    DailyStatsTableCompanion Function({
      required String businessId,
      required String date,
      Value<int> incomeMinor,
      Value<int> expenseMinor,
      Value<int> cashInMinor,
      Value<int> cashOutMinor,
      Value<Map<String, dynamic>> byCategory,
      Value<Map<String, dynamic>> byProject,
      Value<Map<String, dynamic>> byType,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$DailyStatsTableTableUpdateCompanionBuilder =
    DailyStatsTableCompanion Function({
      Value<String> businessId,
      Value<String> date,
      Value<int> incomeMinor,
      Value<int> expenseMinor,
      Value<int> cashInMinor,
      Value<int> cashOutMinor,
      Value<Map<String, dynamic>> byCategory,
      Value<Map<String, dynamic>> byProject,
      Value<Map<String, dynamic>> byType,
      Value<String?> updatedAt,
      Value<int> seq,
      Value<int> rowid,
    });

class $$DailyStatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incomeMinor => $composableBuilder(
    column: $table.incomeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expenseMinor => $composableBuilder(
    column: $table.expenseMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashInMinor => $composableBuilder(
    column: $table.cashInMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashOutMinor => $composableBuilder(
    column: $table.cashOutMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get byCategory => $composableBuilder(
    column: $table.byCategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get byProject => $composableBuilder(
    column: $table.byProject,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>,
    Map<String, dynamic>,
    String
  >
  get byType => $composableBuilder(
    column: $table.byType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incomeMinor => $composableBuilder(
    column: $table.incomeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expenseMinor => $composableBuilder(
    column: $table.expenseMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashInMinor => $composableBuilder(
    column: $table.cashInMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashOutMinor => $composableBuilder(
    column: $table.cashOutMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byCategory => $composableBuilder(
    column: $table.byCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byProject => $composableBuilder(
    column: $table.byProject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byType => $composableBuilder(
    column: $table.byType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get incomeMinor => $composableBuilder(
    column: $table.incomeMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expenseMinor => $composableBuilder(
    column: $table.expenseMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashInMinor => $composableBuilder(
    column: $table.cashInMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashOutMinor => $composableBuilder(
    column: $table.cashOutMinor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get byCategory => $composableBuilder(
    column: $table.byCategory,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String>
  get byProject =>
      $composableBuilder(column: $table.byProject, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>, String> get byType =>
      $composableBuilder(column: $table.byType, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$DailyStatsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStatsTableTable,
          DailyStatsRow,
          $$DailyStatsTableTableFilterComposer,
          $$DailyStatsTableTableOrderingComposer,
          $$DailyStatsTableTableAnnotationComposer,
          $$DailyStatsTableTableCreateCompanionBuilder,
          $$DailyStatsTableTableUpdateCompanionBuilder,
          (
            DailyStatsRow,
            BaseReferences<_$AppDatabase, $DailyStatsTableTable, DailyStatsRow>,
          ),
          DailyStatsRow,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableTableManager(
    _$AppDatabase db,
    $DailyStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> incomeMinor = const Value.absent(),
                Value<int> expenseMinor = const Value.absent(),
                Value<int> cashInMinor = const Value.absent(),
                Value<int> cashOutMinor = const Value.absent(),
                Value<Map<String, dynamic>> byCategory = const Value.absent(),
                Value<Map<String, dynamic>> byProject = const Value.absent(),
                Value<Map<String, dynamic>> byType = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsTableCompanion(
                businessId: businessId,
                date: date,
                incomeMinor: incomeMinor,
                expenseMinor: expenseMinor,
                cashInMinor: cashInMinor,
                cashOutMinor: cashOutMinor,
                byCategory: byCategory,
                byProject: byProject,
                byType: byType,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String date,
                Value<int> incomeMinor = const Value.absent(),
                Value<int> expenseMinor = const Value.absent(),
                Value<int> cashInMinor = const Value.absent(),
                Value<int> cashOutMinor = const Value.absent(),
                Value<Map<String, dynamic>> byCategory = const Value.absent(),
                Value<Map<String, dynamic>> byProject = const Value.absent(),
                Value<Map<String, dynamic>> byType = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsTableCompanion.insert(
                businessId: businessId,
                date: date,
                incomeMinor: incomeMinor,
                expenseMinor: expenseMinor,
                cashInMinor: cashInMinor,
                cashOutMinor: cashOutMinor,
                byCategory: byCategory,
                byProject: byProject,
                byType: byType,
                updatedAt: updatedAt,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStatsTableTable,
      DailyStatsRow,
      $$DailyStatsTableTableFilterComposer,
      $$DailyStatsTableTableOrderingComposer,
      $$DailyStatsTableTableAnnotationComposer,
      $$DailyStatsTableTableCreateCompanionBuilder,
      $$DailyStatsTableTableUpdateCompanionBuilder,
      (
        DailyStatsRow,
        BaseReferences<_$AppDatabase, $DailyStatsTableTable, DailyStatsRow>,
      ),
      DailyStatsRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String businessId,
      required String tableKey,
      Value<int> seq,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> businessId,
      Value<String> tableKey,
      Value<int> seq,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tableKey =>
      $composableBuilder(column: $table.tableKey, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursorRow,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> tableKey = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                businessId: businessId,
                tableKey: tableKey,
                seq: seq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String tableKey,
                Value<int> seq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                businessId: businessId,
                tableKey: tableKey,
                seq: seq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursorRow,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $$LocalMetaTableCreateCompanionBuilder =
    LocalMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalMetaTableUpdateCompanionBuilder =
    LocalMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalMetaTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMetaTable> {
  $$LocalMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMetaTable,
          LocalMetaRow,
          $$LocalMetaTableFilterComposer,
          $$LocalMetaTableOrderingComposer,
          $$LocalMetaTableAnnotationComposer,
          $$LocalMetaTableCreateCompanionBuilder,
          $$LocalMetaTableUpdateCompanionBuilder,
          (
            LocalMetaRow,
            BaseReferences<_$AppDatabase, $LocalMetaTable, LocalMetaRow>,
          ),
          LocalMetaRow,
          PrefetchHooks Function()
        > {
  $$LocalMetaTableTableManager(_$AppDatabase db, $LocalMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMetaTable,
      LocalMetaRow,
      $$LocalMetaTableFilterComposer,
      $$LocalMetaTableOrderingComposer,
      $$LocalMetaTableAnnotationComposer,
      $$LocalMetaTableCreateCompanionBuilder,
      $$LocalMetaTableUpdateCompanionBuilder,
      (
        LocalMetaRow,
        BaseReferences<_$AppDatabase, $LocalMetaTable, LocalMetaRow>,
      ),
      LocalMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$BusinessesTableTableManager get businesses =>
      $$BusinessesTableTableManager(_db, _db.businesses);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CustomFieldsTableTableManager get customFields =>
      $$CustomFieldsTableTableManager(_db, _db.customFields);
  $$PartiesTableTableManager get parties =>
      $$PartiesTableTableManager(_db, _db.parties);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db, _db.settlements);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$DailyStatsTableTableTableManager get dailyStatsTable =>
      $$DailyStatsTableTableTableManager(_db, _db.dailyStatsTable);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$LocalMetaTableTableManager get localMeta =>
      $$LocalMetaTableTableManager(_db, _db.localMeta);
}
