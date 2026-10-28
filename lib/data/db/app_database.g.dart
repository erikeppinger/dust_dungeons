// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<int> colorKey = GeneratedColumn<int>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final int colorKey;
  final DateTime createdAt;
  const Profile({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_key'] = Variable<int>(colorKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      colorKey: Value(colorKey),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorKey: serializer.fromJson<int>(json['colorKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorKey': serializer.toJson<int>(colorKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    int? colorKey,
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    colorKey: colorKey ?? this.colorKey,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorKey == this.colorKey &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorKey;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorKey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorKey != null) 'color_key': colorKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorKey,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<int>(colorKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChoresTable extends Chores with TableInfo<$ChoresTable, Chore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _seedKeyMeta = const VerificationMeta(
    'seedKey',
  );
  @override
  late final GeneratedColumn<String> seedKey = GeneratedColumn<String>(
    'seed_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _customTitleMeta = const VerificationMeta(
    'customTitle',
  );
  @override
  late final GeneratedColumn<String> customTitle = GeneratedColumn<String>(
    'custom_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<int> colorKey = GeneratedColumn<int>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basePointsMeta = const VerificationMeta(
    'basePoints',
  );
  @override
  late final GeneratedColumn<int> basePoints = GeneratedColumn<int>(
    'base_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RepeatType, String> repeatType =
      GeneratedColumn<String>(
        'repeat_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('anytime'),
      ).withConverter<RepeatType>($ChoresTable.$converterrepeatType);
  static const VerificationMeta _repeatIntervalMeta = const VerificationMeta(
    'repeatInterval',
  );
  @override
  late final GeneratedColumn<int> repeatInterval = GeneratedColumn<int>(
    'repeat_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _repeatWeekdaysMeta = const VerificationMeta(
    'repeatWeekdays',
  );
  @override
  late final GeneratedColumn<int> repeatWeekdays = GeneratedColumn<int>(
    'repeat_weekdays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repeatDayOfMonthMeta = const VerificationMeta(
    'repeatDayOfMonth',
  );
  @override
  late final GeneratedColumn<int> repeatDayOfMonth = GeneratedColumn<int>(
    'repeat_day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatStartMeta = const VerificationMeta(
    'repeatStart',
  );
  @override
  late final GeneratedColumn<DateTime> repeatStart = GeneratedColumn<DateTime>(
    'repeat_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatSetAtMeta = const VerificationMeta(
    'repeatSetAt',
  );
  @override
  late final GeneratedColumn<DateTime> repeatSetAt = GeneratedColumn<DateTime>(
    'repeat_set_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seedKey,
    customTitle,
    iconKey,
    colorKey,
    basePoints,
    isArchived,
    sortOrder,
    createdAt,
    repeatType,
    repeatInterval,
    repeatWeekdays,
    repeatDayOfMonth,
    repeatStart,
    repeatSetAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('seed_key')) {
      context.handle(
        _seedKeyMeta,
        seedKey.isAcceptableOrUnknown(data['seed_key']!, _seedKeyMeta),
      );
    }
    if (data.containsKey('custom_title')) {
      context.handle(
        _customTitleMeta,
        customTitle.isAcceptableOrUnknown(
          data['custom_title']!,
          _customTitleMeta,
        ),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_colorKeyMeta);
    }
    if (data.containsKey('base_points')) {
      context.handle(
        _basePointsMeta,
        basePoints.isAcceptableOrUnknown(data['base_points']!, _basePointsMeta),
      );
    } else if (isInserting) {
      context.missing(_basePointsMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('repeat_interval')) {
      context.handle(
        _repeatIntervalMeta,
        repeatInterval.isAcceptableOrUnknown(
          data['repeat_interval']!,
          _repeatIntervalMeta,
        ),
      );
    }
    if (data.containsKey('repeat_weekdays')) {
      context.handle(
        _repeatWeekdaysMeta,
        repeatWeekdays.isAcceptableOrUnknown(
          data['repeat_weekdays']!,
          _repeatWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('repeat_day_of_month')) {
      context.handle(
        _repeatDayOfMonthMeta,
        repeatDayOfMonth.isAcceptableOrUnknown(
          data['repeat_day_of_month']!,
          _repeatDayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('repeat_start')) {
      context.handle(
        _repeatStartMeta,
        repeatStart.isAcceptableOrUnknown(
          data['repeat_start']!,
          _repeatStartMeta,
        ),
      );
    }
    if (data.containsKey('repeat_set_at')) {
      context.handle(
        _repeatSetAtMeta,
        repeatSetAt.isAcceptableOrUnknown(
          data['repeat_set_at']!,
          _repeatSetAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_key'],
      ),
      customTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_title'],
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_key'],
      )!,
      basePoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_points'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      repeatType: $ChoresTable.$converterrepeatType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_type'],
        )!,
      ),
      repeatInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_interval'],
      )!,
      repeatWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_weekdays'],
      )!,
      repeatDayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_day_of_month'],
      ),
      repeatStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}repeat_start'],
      ),
      repeatSetAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}repeat_set_at'],
      ),
    );
  }

  @override
  $ChoresTable createAlias(String alias) {
    return $ChoresTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RepeatType, String, String> $converterrepeatType =
      const EnumNameConverter<RepeatType>(RepeatType.values);
}

class Chore extends DataClass implements Insertable<Chore> {
  final int id;
  final String? seedKey;
  final String? customTitle;
  final String iconKey;
  final int colorKey;
  final int basePoints;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final RepeatType repeatType;
  final int repeatInterval;

  /// Bitmask of weekdays, bit 0 = Monday.
  final int repeatWeekdays;
  final int? repeatDayOfMonth;

  /// First occurrence; `null` falls back to [createdAt].
  final DateTime? repeatStart;

  /// When the schedule was last changed. One-off chores only count
  /// completions made after this.
  final DateTime? repeatSetAt;
  const Chore({
    required this.id,
    this.seedKey,
    this.customTitle,
    required this.iconKey,
    required this.colorKey,
    required this.basePoints,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.repeatType,
    required this.repeatInterval,
    required this.repeatWeekdays,
    this.repeatDayOfMonth,
    this.repeatStart,
    this.repeatSetAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || seedKey != null) {
      map['seed_key'] = Variable<String>(seedKey);
    }
    if (!nullToAbsent || customTitle != null) {
      map['custom_title'] = Variable<String>(customTitle);
    }
    map['icon_key'] = Variable<String>(iconKey);
    map['color_key'] = Variable<int>(colorKey);
    map['base_points'] = Variable<int>(basePoints);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['repeat_type'] = Variable<String>(
        $ChoresTable.$converterrepeatType.toSql(repeatType),
      );
    }
    map['repeat_interval'] = Variable<int>(repeatInterval);
    map['repeat_weekdays'] = Variable<int>(repeatWeekdays);
    if (!nullToAbsent || repeatDayOfMonth != null) {
      map['repeat_day_of_month'] = Variable<int>(repeatDayOfMonth);
    }
    if (!nullToAbsent || repeatStart != null) {
      map['repeat_start'] = Variable<DateTime>(repeatStart);
    }
    if (!nullToAbsent || repeatSetAt != null) {
      map['repeat_set_at'] = Variable<DateTime>(repeatSetAt);
    }
    return map;
  }

  ChoresCompanion toCompanion(bool nullToAbsent) {
    return ChoresCompanion(
      id: Value(id),
      seedKey: seedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(seedKey),
      customTitle: customTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(customTitle),
      iconKey: Value(iconKey),
      colorKey: Value(colorKey),
      basePoints: Value(basePoints),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      repeatType: Value(repeatType),
      repeatInterval: Value(repeatInterval),
      repeatWeekdays: Value(repeatWeekdays),
      repeatDayOfMonth: repeatDayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatDayOfMonth),
      repeatStart: repeatStart == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatStart),
      repeatSetAt: repeatSetAt == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatSetAt),
    );
  }

  factory Chore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chore(
      id: serializer.fromJson<int>(json['id']),
      seedKey: serializer.fromJson<String?>(json['seedKey']),
      customTitle: serializer.fromJson<String?>(json['customTitle']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorKey: serializer.fromJson<int>(json['colorKey']),
      basePoints: serializer.fromJson<int>(json['basePoints']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      repeatType: $ChoresTable.$converterrepeatType.fromJson(
        serializer.fromJson<String>(json['repeatType']),
      ),
      repeatInterval: serializer.fromJson<int>(json['repeatInterval']),
      repeatWeekdays: serializer.fromJson<int>(json['repeatWeekdays']),
      repeatDayOfMonth: serializer.fromJson<int?>(json['repeatDayOfMonth']),
      repeatStart: serializer.fromJson<DateTime?>(json['repeatStart']),
      repeatSetAt: serializer.fromJson<DateTime?>(json['repeatSetAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seedKey': serializer.toJson<String?>(seedKey),
      'customTitle': serializer.toJson<String?>(customTitle),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorKey': serializer.toJson<int>(colorKey),
      'basePoints': serializer.toJson<int>(basePoints),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'repeatType': serializer.toJson<String>(
        $ChoresTable.$converterrepeatType.toJson(repeatType),
      ),
      'repeatInterval': serializer.toJson<int>(repeatInterval),
      'repeatWeekdays': serializer.toJson<int>(repeatWeekdays),
      'repeatDayOfMonth': serializer.toJson<int?>(repeatDayOfMonth),
      'repeatStart': serializer.toJson<DateTime?>(repeatStart),
      'repeatSetAt': serializer.toJson<DateTime?>(repeatSetAt),
    };
  }

  Chore copyWith({
    int? id,
    Value<String?> seedKey = const Value.absent(),
    Value<String?> customTitle = const Value.absent(),
    String? iconKey,
    int? colorKey,
    int? basePoints,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    RepeatType? repeatType,
    int? repeatInterval,
    int? repeatWeekdays,
    Value<int?> repeatDayOfMonth = const Value.absent(),
    Value<DateTime?> repeatStart = const Value.absent(),
    Value<DateTime?> repeatSetAt = const Value.absent(),
  }) => Chore(
    id: id ?? this.id,
    seedKey: seedKey.present ? seedKey.value : this.seedKey,
    customTitle: customTitle.present ? customTitle.value : this.customTitle,
    iconKey: iconKey ?? this.iconKey,
    colorKey: colorKey ?? this.colorKey,
    basePoints: basePoints ?? this.basePoints,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    repeatType: repeatType ?? this.repeatType,
    repeatInterval: repeatInterval ?? this.repeatInterval,
    repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    repeatDayOfMonth: repeatDayOfMonth.present
        ? repeatDayOfMonth.value
        : this.repeatDayOfMonth,
    repeatStart: repeatStart.present ? repeatStart.value : this.repeatStart,
    repeatSetAt: repeatSetAt.present ? repeatSetAt.value : this.repeatSetAt,
  );
  Chore copyWithCompanion(ChoresCompanion data) {
    return Chore(
      id: data.id.present ? data.id.value : this.id,
      seedKey: data.seedKey.present ? data.seedKey.value : this.seedKey,
      customTitle: data.customTitle.present
          ? data.customTitle.value
          : this.customTitle,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      basePoints: data.basePoints.present
          ? data.basePoints.value
          : this.basePoints,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      repeatType: data.repeatType.present
          ? data.repeatType.value
          : this.repeatType,
      repeatInterval: data.repeatInterval.present
          ? data.repeatInterval.value
          : this.repeatInterval,
      repeatWeekdays: data.repeatWeekdays.present
          ? data.repeatWeekdays.value
          : this.repeatWeekdays,
      repeatDayOfMonth: data.repeatDayOfMonth.present
          ? data.repeatDayOfMonth.value
          : this.repeatDayOfMonth,
      repeatStart: data.repeatStart.present
          ? data.repeatStart.value
          : this.repeatStart,
      repeatSetAt: data.repeatSetAt.present
          ? data.repeatSetAt.value
          : this.repeatSetAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chore(')
          ..write('id: $id, ')
          ..write('seedKey: $seedKey, ')
          ..write('customTitle: $customTitle, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('basePoints: $basePoints, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatInterval: $repeatInterval, ')
          ..write('repeatWeekdays: $repeatWeekdays, ')
          ..write('repeatDayOfMonth: $repeatDayOfMonth, ')
          ..write('repeatStart: $repeatStart, ')
          ..write('repeatSetAt: $repeatSetAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seedKey,
    customTitle,
    iconKey,
    colorKey,
    basePoints,
    isArchived,
    sortOrder,
    createdAt,
    repeatType,
    repeatInterval,
    repeatWeekdays,
    repeatDayOfMonth,
    repeatStart,
    repeatSetAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chore &&
          other.id == this.id &&
          other.seedKey == this.seedKey &&
          other.customTitle == this.customTitle &&
          other.iconKey == this.iconKey &&
          other.colorKey == this.colorKey &&
          other.basePoints == this.basePoints &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.repeatType == this.repeatType &&
          other.repeatInterval == this.repeatInterval &&
          other.repeatWeekdays == this.repeatWeekdays &&
          other.repeatDayOfMonth == this.repeatDayOfMonth &&
          other.repeatStart == this.repeatStart &&
          other.repeatSetAt == this.repeatSetAt);
}

class ChoresCompanion extends UpdateCompanion<Chore> {
  final Value<int> id;
  final Value<String?> seedKey;
  final Value<String?> customTitle;
  final Value<String> iconKey;
  final Value<int> colorKey;
  final Value<int> basePoints;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<RepeatType> repeatType;
  final Value<int> repeatInterval;
  final Value<int> repeatWeekdays;
  final Value<int?> repeatDayOfMonth;
  final Value<DateTime?> repeatStart;
  final Value<DateTime?> repeatSetAt;
  const ChoresCompanion({
    this.id = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.customTitle = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.basePoints = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatInterval = const Value.absent(),
    this.repeatWeekdays = const Value.absent(),
    this.repeatDayOfMonth = const Value.absent(),
    this.repeatStart = const Value.absent(),
    this.repeatSetAt = const Value.absent(),
  });
  ChoresCompanion.insert({
    this.id = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.customTitle = const Value.absent(),
    required String iconKey,
    required int colorKey,
    required int basePoints,
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatInterval = const Value.absent(),
    this.repeatWeekdays = const Value.absent(),
    this.repeatDayOfMonth = const Value.absent(),
    this.repeatStart = const Value.absent(),
    this.repeatSetAt = const Value.absent(),
  }) : iconKey = Value(iconKey),
       colorKey = Value(colorKey),
       basePoints = Value(basePoints);
  static Insertable<Chore> custom({
    Expression<int>? id,
    Expression<String>? seedKey,
    Expression<String>? customTitle,
    Expression<String>? iconKey,
    Expression<int>? colorKey,
    Expression<int>? basePoints,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<String>? repeatType,
    Expression<int>? repeatInterval,
    Expression<int>? repeatWeekdays,
    Expression<int>? repeatDayOfMonth,
    Expression<DateTime>? repeatStart,
    Expression<DateTime>? repeatSetAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seedKey != null) 'seed_key': seedKey,
      if (customTitle != null) 'custom_title': customTitle,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorKey != null) 'color_key': colorKey,
      if (basePoints != null) 'base_points': basePoints,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (repeatType != null) 'repeat_type': repeatType,
      if (repeatInterval != null) 'repeat_interval': repeatInterval,
      if (repeatWeekdays != null) 'repeat_weekdays': repeatWeekdays,
      if (repeatDayOfMonth != null) 'repeat_day_of_month': repeatDayOfMonth,
      if (repeatStart != null) 'repeat_start': repeatStart,
      if (repeatSetAt != null) 'repeat_set_at': repeatSetAt,
    });
  }

  ChoresCompanion copyWith({
    Value<int>? id,
    Value<String?>? seedKey,
    Value<String?>? customTitle,
    Value<String>? iconKey,
    Value<int>? colorKey,
    Value<int>? basePoints,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<RepeatType>? repeatType,
    Value<int>? repeatInterval,
    Value<int>? repeatWeekdays,
    Value<int?>? repeatDayOfMonth,
    Value<DateTime?>? repeatStart,
    Value<DateTime?>? repeatSetAt,
  }) {
    return ChoresCompanion(
      id: id ?? this.id,
      seedKey: seedKey ?? this.seedKey,
      customTitle: customTitle ?? this.customTitle,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      basePoints: basePoints ?? this.basePoints,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatDayOfMonth: repeatDayOfMonth ?? this.repeatDayOfMonth,
      repeatStart: repeatStart ?? this.repeatStart,
      repeatSetAt: repeatSetAt ?? this.repeatSetAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seedKey.present) {
      map['seed_key'] = Variable<String>(seedKey.value);
    }
    if (customTitle.present) {
      map['custom_title'] = Variable<String>(customTitle.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<int>(colorKey.value);
    }
    if (basePoints.present) {
      map['base_points'] = Variable<int>(basePoints.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (repeatType.present) {
      map['repeat_type'] = Variable<String>(
        $ChoresTable.$converterrepeatType.toSql(repeatType.value),
      );
    }
    if (repeatInterval.present) {
      map['repeat_interval'] = Variable<int>(repeatInterval.value);
    }
    if (repeatWeekdays.present) {
      map['repeat_weekdays'] = Variable<int>(repeatWeekdays.value);
    }
    if (repeatDayOfMonth.present) {
      map['repeat_day_of_month'] = Variable<int>(repeatDayOfMonth.value);
    }
    if (repeatStart.present) {
      map['repeat_start'] = Variable<DateTime>(repeatStart.value);
    }
    if (repeatSetAt.present) {
      map['repeat_set_at'] = Variable<DateTime>(repeatSetAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoresCompanion(')
          ..write('id: $id, ')
          ..write('seedKey: $seedKey, ')
          ..write('customTitle: $customTitle, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorKey: $colorKey, ')
          ..write('basePoints: $basePoints, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatInterval: $repeatInterval, ')
          ..write('repeatWeekdays: $repeatWeekdays, ')
          ..write('repeatDayOfMonth: $repeatDayOfMonth, ')
          ..write('repeatStart: $repeatStart, ')
          ..write('repeatSetAt: $repeatSetAt')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _choreIdMeta = const VerificationMeta(
    'choreId',
  );
  @override
  late final GeneratedColumn<int> choreId = GeneratedColumn<int>(
    'chore_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chores (id)',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsAwardedMeta = const VerificationMeta(
    'pointsAwarded',
  );
  @override
  late final GeneratedColumn<int> pointsAwarded = GeneratedColumn<int>(
    'points_awarded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _undoneAtMeta = const VerificationMeta(
    'undoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
    'undone_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    choreId,
    profileId,
    completedAt,
    pointsAwarded,
    undoneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chore_id')) {
      context.handle(
        _choreIdMeta,
        choreId.isAcceptableOrUnknown(data['chore_id']!, _choreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_choreIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('points_awarded')) {
      context.handle(
        _pointsAwardedMeta,
        pointsAwarded.isAcceptableOrUnknown(
          data['points_awarded']!,
          _pointsAwardedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointsAwardedMeta);
    }
    if (data.containsKey('undone_at')) {
      context.handle(
        _undoneAtMeta,
        undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      choreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chore_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      pointsAwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_awarded'],
      )!,
      undoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}undone_at'],
      ),
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }
}

class Completion extends DataClass implements Insertable<Completion> {
  final int id;
  final int choreId;
  final int profileId;
  final DateTime completedAt;
  final int pointsAwarded;
  final DateTime? undoneAt;
  const Completion({
    required this.id,
    required this.choreId,
    required this.profileId,
    required this.completedAt,
    required this.pointsAwarded,
    this.undoneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chore_id'] = Variable<int>(choreId);
    map['profile_id'] = Variable<int>(profileId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['points_awarded'] = Variable<int>(pointsAwarded);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      choreId: Value(choreId),
      profileId: Value(profileId),
      completedAt: Value(completedAt),
      pointsAwarded: Value(pointsAwarded),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      id: serializer.fromJson<int>(json['id']),
      choreId: serializer.fromJson<int>(json['choreId']),
      profileId: serializer.fromJson<int>(json['profileId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      pointsAwarded: serializer.fromJson<int>(json['pointsAwarded']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'choreId': serializer.toJson<int>(choreId),
      'profileId': serializer.toJson<int>(profileId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'pointsAwarded': serializer.toJson<int>(pointsAwarded),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
    };
  }

  Completion copyWith({
    int? id,
    int? choreId,
    int? profileId,
    DateTime? completedAt,
    int? pointsAwarded,
    Value<DateTime?> undoneAt = const Value.absent(),
  }) => Completion(
    id: id ?? this.id,
    choreId: choreId ?? this.choreId,
    profileId: profileId ?? this.profileId,
    completedAt: completedAt ?? this.completedAt,
    pointsAwarded: pointsAwarded ?? this.pointsAwarded,
    undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      choreId: data.choreId.present ? data.choreId.value : this.choreId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      pointsAwarded: data.pointsAwarded.present
          ? data.pointsAwarded.value
          : this.pointsAwarded,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('id: $id, ')
          ..write('choreId: $choreId, ')
          ..write('profileId: $profileId, ')
          ..write('completedAt: $completedAt, ')
          ..write('pointsAwarded: $pointsAwarded, ')
          ..write('undoneAt: $undoneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, choreId, profileId, completedAt, pointsAwarded, undoneAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.choreId == this.choreId &&
          other.profileId == this.profileId &&
          other.completedAt == this.completedAt &&
          other.pointsAwarded == this.pointsAwarded &&
          other.undoneAt == this.undoneAt);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<int> id;
  final Value<int> choreId;
  final Value<int> profileId;
  final Value<DateTime> completedAt;
  final Value<int> pointsAwarded;
  final Value<DateTime?> undoneAt;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.choreId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.pointsAwarded = const Value.absent(),
    this.undoneAt = const Value.absent(),
  });
  CompletionsCompanion.insert({
    this.id = const Value.absent(),
    required int choreId,
    required int profileId,
    required DateTime completedAt,
    required int pointsAwarded,
    this.undoneAt = const Value.absent(),
  }) : choreId = Value(choreId),
       profileId = Value(profileId),
       completedAt = Value(completedAt),
       pointsAwarded = Value(pointsAwarded);
  static Insertable<Completion> custom({
    Expression<int>? id,
    Expression<int>? choreId,
    Expression<int>? profileId,
    Expression<DateTime>? completedAt,
    Expression<int>? pointsAwarded,
    Expression<DateTime>? undoneAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (choreId != null) 'chore_id': choreId,
      if (profileId != null) 'profile_id': profileId,
      if (completedAt != null) 'completed_at': completedAt,
      if (pointsAwarded != null) 'points_awarded': pointsAwarded,
      if (undoneAt != null) 'undone_at': undoneAt,
    });
  }

  CompletionsCompanion copyWith({
    Value<int>? id,
    Value<int>? choreId,
    Value<int>? profileId,
    Value<DateTime>? completedAt,
    Value<int>? pointsAwarded,
    Value<DateTime?>? undoneAt,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      choreId: choreId ?? this.choreId,
      profileId: profileId ?? this.profileId,
      completedAt: completedAt ?? this.completedAt,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      undoneAt: undoneAt ?? this.undoneAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (choreId.present) {
      map['chore_id'] = Variable<int>(choreId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (pointsAwarded.present) {
      map['points_awarded'] = Variable<int>(pointsAwarded.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('choreId: $choreId, ')
          ..write('profileId: $profileId, ')
          ..write('completedAt: $completedAt, ')
          ..write('pointsAwarded: $pointsAwarded, ')
          ..write('undoneAt: $undoneAt')
          ..write(')'))
        .toString();
  }
}

class $PointLedgerTable extends PointLedger
    with TableInfo<$PointLedgerTable, LedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LedgerReason, String> reason =
      GeneratedColumn<String>(
        'reason',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LedgerReason>($PointLedgerTable.$converterreason);
  static const VerificationMeta _completionIdMeta = const VerificationMeta(
    'completionId',
  );
  @override
  late final GeneratedColumn<int> completionId = GeneratedColumn<int>(
    'completion_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completions (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    delta,
    reason,
    completionId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'point_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('completion_id')) {
      context.handle(
        _completionIdMeta,
        completionId.isAcceptableOrUnknown(
          data['completion_id']!,
          _completionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      reason: $PointLedgerTable.$converterreason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reason'],
        )!,
      ),
      completionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PointLedgerTable createAlias(String alias) {
    return $PointLedgerTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LedgerReason, String, String> $converterreason =
      const EnumNameConverter<LedgerReason>(LedgerReason.values);
}

class LedgerEntry extends DataClass implements Insertable<LedgerEntry> {
  final int id;
  final int profileId;
  final int delta;
  final LedgerReason reason;
  final int? completionId;
  final DateTime createdAt;
  const LedgerEntry({
    required this.id,
    required this.profileId,
    required this.delta,
    required this.reason,
    this.completionId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['delta'] = Variable<int>(delta);
    {
      map['reason'] = Variable<String>(
        $PointLedgerTable.$converterreason.toSql(reason),
      );
    }
    if (!nullToAbsent || completionId != null) {
      map['completion_id'] = Variable<int>(completionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PointLedgerCompanion toCompanion(bool nullToAbsent) {
    return PointLedgerCompanion(
      id: Value(id),
      profileId: Value(profileId),
      delta: Value(delta),
      reason: Value(reason),
      completionId: completionId == null && nullToAbsent
          ? const Value.absent()
          : Value(completionId),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntry(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: $PointLedgerTable.$converterreason.fromJson(
        serializer.fromJson<String>(json['reason']),
      ),
      completionId: serializer.fromJson<int?>(json['completionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(
        $PointLedgerTable.$converterreason.toJson(reason),
      ),
      'completionId': serializer.toJson<int?>(completionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerEntry copyWith({
    int? id,
    int? profileId,
    int? delta,
    LedgerReason? reason,
    Value<int?> completionId = const Value.absent(),
    DateTime? createdAt,
  }) => LedgerEntry(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    delta: delta ?? this.delta,
    reason: reason ?? this.reason,
    completionId: completionId.present ? completionId.value : this.completionId,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerEntry copyWithCompanion(PointLedgerCompanion data) {
    return LedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      completionId: data.completionId.present
          ? data.completionId.value
          : this.completionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntry(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('completionId: $completionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, delta, reason, completionId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntry &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.completionId == this.completionId &&
          other.createdAt == this.createdAt);
}

class PointLedgerCompanion extends UpdateCompanion<LedgerEntry> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<int> delta;
  final Value<LedgerReason> reason;
  final Value<int?> completionId;
  final Value<DateTime> createdAt;
  const PointLedgerCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.completionId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PointLedgerCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required int delta,
    required LedgerReason reason,
    this.completionId = const Value.absent(),
    required DateTime createdAt,
  }) : profileId = Value(profileId),
       delta = Value(delta),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<LedgerEntry> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<int>? completionId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (completionId != null) 'completion_id': completionId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PointLedgerCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<int>? delta,
    Value<LedgerReason>? reason,
    Value<int?>? completionId,
    Value<DateTime>? createdAt,
  }) {
    return PointLedgerCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      completionId: completionId ?? this.completionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(
        $PointLedgerTable.$converterreason.toSql(reason.value),
      );
    }
    if (completionId.present) {
      map['completion_id'] = Variable<int>(completionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointLedgerCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('completionId: $completionId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingEntry> instance, {
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
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String value;
  const SettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
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

  SettingEntry copyWith({String? key, String? value}) =>
      SettingEntry(key: key ?? this.key, value: value ?? this.value);
  SettingEntry copyWithCompanion(SettingsCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
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
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingEntry> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
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
  late final $ChoresTable chores = $ChoresTable(this);
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $PointLedgerTable pointLedger = $PointLedgerTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    chores,
    completions,
    pointLedger,
    settings,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> colorKey,
  Value<DateTime> createdAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorKey,
  Value<DateTime> createdAt,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CompletionsTable, List<Completion>>
  _completionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completions,
    aliasName: 'profiles__id__completions__profile_id',
  );

  $$CompletionsTableProcessedTableManager get completionsRefs {
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_completionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PointLedgerTable, List<LedgerEntry>>
  _pointLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pointLedger,
    aliasName: 'profiles__id__point_ledger__profile_id',
  );

  $$PointLedgerTableProcessedTableManager get pointLedgerRefs {
    final manager = $$PointLedgerTableTableManager(
      $_db,
      $_db.pointLedger,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pointLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> completionsRefs(
    Expression<bool> Function($$CompletionsTableFilterComposer f) f,
  ) {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pointLedgerRefs(
    Expression<bool> Function($$PointLedgerTableFilterComposer f) f,
  ) {
    final $$PointLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pointLedger,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointLedgerTableFilterComposer(
            $db: $db,
            $table: $db.pointLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> completionsRefs<T extends Object>(
    Expression<T> Function($$CompletionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pointLedgerRefs<T extends Object>(
    Expression<T> Function($$PointLedgerTableAnnotationComposer a) f,
  ) {
    final $$PointLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pointLedger,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.pointLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, $$ProfilesTableReferences),
          Profile,
          PrefetchHooks Function({bool completionsRefs, bool pointLedgerRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                colorKey: colorKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> colorKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                colorKey: colorKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  $$ProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({completionsRefs = false, pointLedgerRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionsRefs) db.completions,
                    if (pointLedgerRefs) db.pointLedger,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completionsRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          Completion,
                          $CompletionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._completionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).completionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'profile_id',
                          typedResults: items,
                        ),
                      if (pointLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          LedgerEntry,
                          $PointLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._pointLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).pointLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'profile_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, $$ProfilesTableReferences),
      Profile,
      PrefetchHooks Function({bool completionsRefs, bool pointLedgerRefs})
    >;
typedef $$ChoresTableCreateCompanionBuilder = ChoresCompanion Function({
  Value<int> id,
  Value<String?> seedKey,
  Value<String?> customTitle,
  required String iconKey,
  required int colorKey,
  required int basePoints,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<RepeatType> repeatType,
  Value<int> repeatInterval,
  Value<int> repeatWeekdays,
  Value<int?> repeatDayOfMonth,
  Value<DateTime?> repeatStart,
  Value<DateTime?> repeatSetAt,
});
typedef $$ChoresTableUpdateCompanionBuilder = ChoresCompanion Function({
  Value<int> id,
  Value<String?> seedKey,
  Value<String?> customTitle,
  Value<String> iconKey,
  Value<int> colorKey,
  Value<int> basePoints,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<RepeatType> repeatType,
  Value<int> repeatInterval,
  Value<int> repeatWeekdays,
  Value<int?> repeatDayOfMonth,
  Value<DateTime?> repeatStart,
  Value<DateTime?> repeatSetAt,
});

final class $$ChoresTableReferences
    extends BaseReferences<_$AppDatabase, $ChoresTable, Chore> {
  $$ChoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CompletionsTable, List<Completion>>
  _completionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completions,
    aliasName: 'chores__id__completions__chore_id',
  );

  $$CompletionsTableProcessedTableManager get completionsRefs {
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.choreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_completionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChoresTableFilterComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableFilterComposer({
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

  ColumnFilters<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customTitle => $composableBuilder(
    column: $table.customTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePoints => $composableBuilder(
    column: $table.basePoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RepeatType, RepeatType, String>
  get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatWeekdays => $composableBuilder(
    column: $table.repeatWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatDayOfMonth => $composableBuilder(
    column: $table.repeatDayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get repeatStart => $composableBuilder(
    column: $table.repeatStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get repeatSetAt => $composableBuilder(
    column: $table.repeatSetAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> completionsRefs(
    Expression<bool> Function($$CompletionsTableFilterComposer f) f,
  ) {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableOrderingComposer({
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

  ColumnOrderings<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customTitle => $composableBuilder(
    column: $table.customTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePoints => $composableBuilder(
    column: $table.basePoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatWeekdays => $composableBuilder(
    column: $table.repeatWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatDayOfMonth => $composableBuilder(
    column: $table.repeatDayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get repeatStart => $composableBuilder(
    column: $table.repeatStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get repeatSetAt => $composableBuilder(
    column: $table.repeatSetAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoresTable> {
  $$ChoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seedKey =>
      $composableBuilder(column: $table.seedKey, builder: (column) => column);

  GeneratedColumn<String> get customTitle => $composableBuilder(
    column: $table.customTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<int> get basePoints => $composableBuilder(
    column: $table.basePoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RepeatType, String> get repeatType =>
      $composableBuilder(
        column: $table.repeatType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get repeatInterval => $composableBuilder(
    column: $table.repeatInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatWeekdays => $composableBuilder(
    column: $table.repeatWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatDayOfMonth => $composableBuilder(
    column: $table.repeatDayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get repeatStart => $composableBuilder(
    column: $table.repeatStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get repeatSetAt => $composableBuilder(
    column: $table.repeatSetAt,
    builder: (column) => column,
  );

  Expression<T> completionsRefs<T extends Object>(
    Expression<T> Function($$CompletionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoresTable,
          Chore,
          $$ChoresTableFilterComposer,
          $$ChoresTableOrderingComposer,
          $$ChoresTableAnnotationComposer,
          $$ChoresTableCreateCompanionBuilder,
          $$ChoresTableUpdateCompanionBuilder,
          (Chore, $$ChoresTableReferences),
          Chore,
          PrefetchHooks Function({bool completionsRefs})
        > {
  $$ChoresTableTableManager(_$AppDatabase db, $ChoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<String?> customTitle = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> colorKey = const Value.absent(),
                Value<int> basePoints = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<RepeatType> repeatType = const Value.absent(),
                Value<int> repeatInterval = const Value.absent(),
                Value<int> repeatWeekdays = const Value.absent(),
                Value<int?> repeatDayOfMonth = const Value.absent(),
                Value<DateTime?> repeatStart = const Value.absent(),
                Value<DateTime?> repeatSetAt = const Value.absent(),
              }) => ChoresCompanion(
                id: id,
                seedKey: seedKey,
                customTitle: customTitle,
                iconKey: iconKey,
                colorKey: colorKey,
                basePoints: basePoints,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                repeatType: repeatType,
                repeatInterval: repeatInterval,
                repeatWeekdays: repeatWeekdays,
                repeatDayOfMonth: repeatDayOfMonth,
                repeatStart: repeatStart,
                repeatSetAt: repeatSetAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<String?> customTitle = const Value.absent(),
                required String iconKey,
                required int colorKey,
                required int basePoints,
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<RepeatType> repeatType = const Value.absent(),
                Value<int> repeatInterval = const Value.absent(),
                Value<int> repeatWeekdays = const Value.absent(),
                Value<int?> repeatDayOfMonth = const Value.absent(),
                Value<DateTime?> repeatStart = const Value.absent(),
                Value<DateTime?> repeatSetAt = const Value.absent(),
              }) => ChoresCompanion.insert(
                id: id,
                seedKey: seedKey,
                customTitle: customTitle,
                iconKey: iconKey,
                colorKey: colorKey,
                basePoints: basePoints,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                repeatType: repeatType,
                repeatInterval: repeatInterval,
                repeatWeekdays: repeatWeekdays,
                repeatDayOfMonth: repeatDayOfMonth,
                repeatStart: repeatStart,
                repeatSetAt: repeatSetAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChoresTable, Chore>(table),
                  $$ChoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (completionsRefs) db.completions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (completionsRefs)
                    await $_getPrefetchedDataByColumns<
                      Chore,
                      $ChoresTable,
                      Completion,
                      $CompletionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChoresTableReferences
                          ._completionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ChoresTableReferences(
                        db,
                        table,
                        p0,
                      ).completionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'chore_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoresTable,
      Chore,
      $$ChoresTableFilterComposer,
      $$ChoresTableOrderingComposer,
      $$ChoresTableAnnotationComposer,
      $$ChoresTableCreateCompanionBuilder,
      $$ChoresTableUpdateCompanionBuilder,
      (Chore, $$ChoresTableReferences),
      Chore,
      PrefetchHooks Function({bool completionsRefs})
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      required int choreId,
      required int profileId,
      required DateTime completedAt,
      required int pointsAwarded,
      Value<DateTime?> undoneAt,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      Value<int> choreId,
      Value<int> profileId,
      Value<DateTime> completedAt,
      Value<int> pointsAwarded,
      Value<DateTime?> undoneAt,
    });

final class $$CompletionsTableReferences
    extends BaseReferences<_$AppDatabase, $CompletionsTable, Completion> {
  $$CompletionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChoresTable _choreIdTable(_$AppDatabase db) =>
      db.chores.createAlias('completions__chore_id__chores__id');

  $$ChoresTableProcessedTableManager get choreId {
    final $_column = $_itemColumn<int>('chore_id')!;

    final manager = $$ChoresTableTableManager(
      $_db,
      $_db.chores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_choreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('completions__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PointLedgerTable, List<LedgerEntry>>
  _pointLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pointLedger,
    aliasName: 'completions__id__point_ledger__completion_id',
  );

  $$PointLedgerTableProcessedTableManager get pointLedgerRefs {
    final manager = $$PointLedgerTableTableManager(
      $_db,
      $_db.pointLedger,
    ).filter((f) => f.completionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pointLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
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

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsAwarded => $composableBuilder(
    column: $table.pointsAwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChoresTableFilterComposer get choreId {
    final $$ChoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableFilterComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pointLedgerRefs(
    Expression<bool> Function($$PointLedgerTableFilterComposer f) f,
  ) {
    final $$PointLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pointLedger,
      getReferencedColumn: (t) => t.completionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointLedgerTableFilterComposer(
            $db: $db,
            $table: $db.pointLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsAwarded => $composableBuilder(
    column: $table.pointsAwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChoresTableOrderingComposer get choreId {
    final $$ChoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableOrderingComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointsAwarded => $composableBuilder(
    column: $table.pointsAwarded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);

  $$ChoresTableAnnotationComposer get choreId {
    final $$ChoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.choreId,
      referencedTable: $db.chores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoresTableAnnotationComposer(
            $db: $db,
            $table: $db.chores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pointLedgerRefs<T extends Object>(
    Expression<T> Function($$PointLedgerTableAnnotationComposer a) f,
  ) {
    final $$PointLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pointLedger,
      getReferencedColumn: (t) => t.completionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PointLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.pointLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletionsTable,
          Completion,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (Completion, $$CompletionsTableReferences),
          Completion,
          PrefetchHooks Function({
            bool choreId,
            bool profileId,
            bool pointLedgerRefs,
          })
        > {
  $$CompletionsTableTableManager(_$AppDatabase db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> choreId = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> pointsAwarded = const Value.absent(),
                Value<DateTime?> undoneAt = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                choreId: choreId,
                profileId: profileId,
                completedAt: completedAt,
                pointsAwarded: pointsAwarded,
                undoneAt: undoneAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int choreId,
                required int profileId,
                required DateTime completedAt,
                required int pointsAwarded,
                Value<DateTime?> undoneAt = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                choreId: choreId,
                profileId: profileId,
                completedAt: completedAt,
                pointsAwarded: pointsAwarded,
                undoneAt: undoneAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletionsTable, Completion>(table),
                  $$CompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({choreId = false, profileId = false, pointLedgerRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pointLedgerRefs) db.pointLedger,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (choreId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.choreId,
                            referencedTable: $$CompletionsTableReferences
                                ._choreIdTable(db),
                            referencedColumn: $$CompletionsTableReferences
                                ._choreIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (profileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.profileId,
                            referencedTable: $$CompletionsTableReferences
                                ._profileIdTable(db),
                            referencedColumn: $$CompletionsTableReferences
                                ._profileIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pointLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          Completion,
                          $CompletionsTable,
                          LedgerEntry,
                          $PointLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$CompletionsTableReferences
                              ._pointLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pointLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'completion_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletionsTable,
      Completion,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (Completion, $$CompletionsTableReferences),
      Completion,
      PrefetchHooks Function({
        bool choreId,
        bool profileId,
        bool pointLedgerRefs,
      })
    >;
typedef $$PointLedgerTableCreateCompanionBuilder =
    PointLedgerCompanion Function({
      Value<int> id,
      required int profileId,
      required int delta,
      required LedgerReason reason,
      Value<int?> completionId,
      required DateTime createdAt,
    });
typedef $$PointLedgerTableUpdateCompanionBuilder =
    PointLedgerCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<int> delta,
      Value<LedgerReason> reason,
      Value<int?> completionId,
      Value<DateTime> createdAt,
    });

final class $$PointLedgerTableReferences
    extends BaseReferences<_$AppDatabase, $PointLedgerTable, LedgerEntry> {
  $$PointLedgerTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('point_ledger__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<int>('profile_id')!;

    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CompletionsTable _completionIdTable(_$AppDatabase db) => db
      .completions
      .createAlias('point_ledger__completion_id__completions__id');

  $$CompletionsTableProcessedTableManager? get completionId {
    final $_column = $_itemColumn<int>('completion_id');
    if ($_column == null) return null;
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PointLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $PointLedgerTable> {
  $$PointLedgerTableFilterComposer({
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

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LedgerReason, LedgerReason, String>
  get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletionsTableFilterComposer get completionId {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $PointLedgerTable> {
  $$PointLedgerTableOrderingComposer({
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

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletionsTableOrderingComposer get completionId {
    final $$CompletionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableOrderingComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $PointLedgerTable> {
  $$PointLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LedgerReason, String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletionsTableAnnotationComposer get completionId {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PointLedgerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PointLedgerTable,
          LedgerEntry,
          $$PointLedgerTableFilterComposer,
          $$PointLedgerTableOrderingComposer,
          $$PointLedgerTableAnnotationComposer,
          $$PointLedgerTableCreateCompanionBuilder,
          $$PointLedgerTableUpdateCompanionBuilder,
          (LedgerEntry, $$PointLedgerTableReferences),
          LedgerEntry,
          PrefetchHooks Function({bool profileId, bool completionId})
        > {
  $$PointLedgerTableTableManager(_$AppDatabase db, $PointLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<LedgerReason> reason = const Value.absent(),
                Value<int?> completionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PointLedgerCompanion(
                id: id,
                profileId: profileId,
                delta: delta,
                reason: reason,
                completionId: completionId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required int delta,
                required LedgerReason reason,
                Value<int?> completionId = const Value.absent(),
                required DateTime createdAt,
              }) => PointLedgerCompanion.insert(
                id: id,
                profileId: profileId,
                delta: delta,
                reason: reason,
                completionId: completionId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PointLedgerTable, LedgerEntry>(table),
                  $$PointLedgerTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false, completionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$PointLedgerTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$PointLedgerTableReferences
                            ._profileIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (completionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.completionId,
                        referencedTable: $$PointLedgerTableReferences
                            ._completionIdTable(db),
                        referencedColumn: $$PointLedgerTableReferences
                            ._completionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PointLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PointLedgerTable,
      LedgerEntry,
      $$PointLedgerTableFilterComposer,
      $$PointLedgerTableOrderingComposer,
      $$PointLedgerTableAnnotationComposer,
      $$PointLedgerTableCreateCompanionBuilder,
      $$PointLedgerTableUpdateCompanionBuilder,
      (LedgerEntry, $$PointLedgerTableReferences),
      LedgerEntry,
      PrefetchHooks Function({bool profileId, bool completionId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingEntry,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingEntry,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>,
          ),
          SettingEntry,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingEntry>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingEntry,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingEntry,
        BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>,
      ),
      SettingEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ChoresTableTableManager get chores =>
      $$ChoresTableTableManager(_db, _db.chores);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$PointLedgerTableTableManager get pointLedger =>
      $$PointLedgerTableTableManager(_db, _db.pointLedger);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
