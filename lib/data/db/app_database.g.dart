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
  static const VerificationMeta _avatarSkinMeta = const VerificationMeta(
    'avatarSkin',
  );
  @override
  late final GeneratedColumn<int> avatarSkin = GeneratedColumn<int>(
    'avatar_skin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avatarHairMeta = const VerificationMeta(
    'avatarHair',
  );
  @override
  late final GeneratedColumn<int> avatarHair = GeneratedColumn<int>(
    'avatar_hair',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avatarCapeMeta = const VerificationMeta(
    'avatarCape',
  );
  @override
  late final GeneratedColumn<int> avatarCape = GeneratedColumn<int>(
    'avatar_cape',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _avatarHatMeta = const VerificationMeta(
    'avatarHat',
  );
  @override
  late final GeneratedColumn<int> avatarHat = GeneratedColumn<int>(
    'avatar_hat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _storyModeMeta = const VerificationMeta(
    'storyMode',
  );
  @override
  late final GeneratedColumn<bool> storyMode = GeneratedColumn<bool>(
    'story_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("story_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _slowModeMeta = const VerificationMeta(
    'slowMode',
  );
  @override
  late final GeneratedColumn<bool> slowMode = GeneratedColumn<bool>(
    'slow_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("slow_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorKey,
    createdAt,
    avatarSkin,
    avatarHair,
    avatarCape,
    avatarHat,
    storyMode,
    slowMode,
    archivedAt,
  ];
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
    if (data.containsKey('avatar_skin')) {
      context.handle(
        _avatarSkinMeta,
        avatarSkin.isAcceptableOrUnknown(data['avatar_skin']!, _avatarSkinMeta),
      );
    }
    if (data.containsKey('avatar_hair')) {
      context.handle(
        _avatarHairMeta,
        avatarHair.isAcceptableOrUnknown(data['avatar_hair']!, _avatarHairMeta),
      );
    }
    if (data.containsKey('avatar_cape')) {
      context.handle(
        _avatarCapeMeta,
        avatarCape.isAcceptableOrUnknown(data['avatar_cape']!, _avatarCapeMeta),
      );
    }
    if (data.containsKey('avatar_hat')) {
      context.handle(
        _avatarHatMeta,
        avatarHat.isAcceptableOrUnknown(data['avatar_hat']!, _avatarHatMeta),
      );
    }
    if (data.containsKey('story_mode')) {
      context.handle(
        _storyModeMeta,
        storyMode.isAcceptableOrUnknown(data['story_mode']!, _storyModeMeta),
      );
    }
    if (data.containsKey('slow_mode')) {
      context.handle(
        _slowModeMeta,
        slowMode.isAcceptableOrUnknown(data['slow_mode']!, _slowModeMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
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
      avatarSkin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_skin'],
      )!,
      avatarHair: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_hair'],
      )!,
      avatarCape: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_cape'],
      )!,
      avatarHat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_hat'],
      )!,
      storyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}story_mode'],
      )!,
      slowMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}slow_mode'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
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
  final int avatarSkin;
  final int avatarHair;
  final int avatarCape;
  final int avatarHat;

  /// Story mode: fights cannot be lost, wider timing.
  final bool storyMode;

  /// Slow mode: fights play at 70 % tempo.
  final bool slowMode;

  /// Removed people are hidden but keep their history.
  final DateTime? archivedAt;
  const Profile({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.createdAt,
    required this.avatarSkin,
    required this.avatarHair,
    required this.avatarCape,
    required this.avatarHat,
    required this.storyMode,
    required this.slowMode,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_key'] = Variable<int>(colorKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['avatar_skin'] = Variable<int>(avatarSkin);
    map['avatar_hair'] = Variable<int>(avatarHair);
    map['avatar_cape'] = Variable<int>(avatarCape);
    map['avatar_hat'] = Variable<int>(avatarHat);
    map['story_mode'] = Variable<bool>(storyMode);
    map['slow_mode'] = Variable<bool>(slowMode);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      colorKey: Value(colorKey),
      createdAt: Value(createdAt),
      avatarSkin: Value(avatarSkin),
      avatarHair: Value(avatarHair),
      avatarCape: Value(avatarCape),
      avatarHat: Value(avatarHat),
      storyMode: Value(storyMode),
      slowMode: Value(slowMode),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
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
      avatarSkin: serializer.fromJson<int>(json['avatarSkin']),
      avatarHair: serializer.fromJson<int>(json['avatarHair']),
      avatarCape: serializer.fromJson<int>(json['avatarCape']),
      avatarHat: serializer.fromJson<int>(json['avatarHat']),
      storyMode: serializer.fromJson<bool>(json['storyMode']),
      slowMode: serializer.fromJson<bool>(json['slowMode']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
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
      'avatarSkin': serializer.toJson<int>(avatarSkin),
      'avatarHair': serializer.toJson<int>(avatarHair),
      'avatarCape': serializer.toJson<int>(avatarCape),
      'avatarHat': serializer.toJson<int>(avatarHat),
      'storyMode': serializer.toJson<bool>(storyMode),
      'slowMode': serializer.toJson<bool>(slowMode),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    int? colorKey,
    DateTime? createdAt,
    int? avatarSkin,
    int? avatarHair,
    int? avatarCape,
    int? avatarHat,
    bool? storyMode,
    bool? slowMode,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    colorKey: colorKey ?? this.colorKey,
    createdAt: createdAt ?? this.createdAt,
    avatarSkin: avatarSkin ?? this.avatarSkin,
    avatarHair: avatarHair ?? this.avatarHair,
    avatarCape: avatarCape ?? this.avatarCape,
    avatarHat: avatarHat ?? this.avatarHat,
    storyMode: storyMode ?? this.storyMode,
    slowMode: slowMode ?? this.slowMode,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      avatarSkin: data.avatarSkin.present
          ? data.avatarSkin.value
          : this.avatarSkin,
      avatarHair: data.avatarHair.present
          ? data.avatarHair.value
          : this.avatarHair,
      avatarCape: data.avatarCape.present
          ? data.avatarCape.value
          : this.avatarCape,
      avatarHat: data.avatarHat.present ? data.avatarHat.value : this.avatarHat,
      storyMode: data.storyMode.present ? data.storyMode.value : this.storyMode,
      slowMode: data.slowMode.present ? data.slowMode.value : this.slowMode,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarSkin: $avatarSkin, ')
          ..write('avatarHair: $avatarHair, ')
          ..write('avatarCape: $avatarCape, ')
          ..write('avatarHat: $avatarHat, ')
          ..write('storyMode: $storyMode, ')
          ..write('slowMode: $slowMode, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorKey,
    createdAt,
    avatarSkin,
    avatarHair,
    avatarCape,
    avatarHat,
    storyMode,
    slowMode,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorKey == this.colorKey &&
          other.createdAt == this.createdAt &&
          other.avatarSkin == this.avatarSkin &&
          other.avatarHair == this.avatarHair &&
          other.avatarCape == this.avatarCape &&
          other.avatarHat == this.avatarHat &&
          other.storyMode == this.storyMode &&
          other.slowMode == this.slowMode &&
          other.archivedAt == this.archivedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorKey;
  final Value<DateTime> createdAt;
  final Value<int> avatarSkin;
  final Value<int> avatarHair;
  final Value<int> avatarCape;
  final Value<int> avatarHat;
  final Value<bool> storyMode;
  final Value<bool> slowMode;
  final Value<DateTime?> archivedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarSkin = const Value.absent(),
    this.avatarHair = const Value.absent(),
    this.avatarCape = const Value.absent(),
    this.avatarHat = const Value.absent(),
    this.storyMode = const Value.absent(),
    this.slowMode = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarSkin = const Value.absent(),
    this.avatarHair = const Value.absent(),
    this.avatarCape = const Value.absent(),
    this.avatarHat = const Value.absent(),
    this.storyMode = const Value.absent(),
    this.slowMode = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorKey,
    Expression<DateTime>? createdAt,
    Expression<int>? avatarSkin,
    Expression<int>? avatarHair,
    Expression<int>? avatarCape,
    Expression<int>? avatarHat,
    Expression<bool>? storyMode,
    Expression<bool>? slowMode,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorKey != null) 'color_key': colorKey,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarSkin != null) 'avatar_skin': avatarSkin,
      if (avatarHair != null) 'avatar_hair': avatarHair,
      if (avatarCape != null) 'avatar_cape': avatarCape,
      if (avatarHat != null) 'avatar_hat': avatarHat,
      if (storyMode != null) 'story_mode': storyMode,
      if (slowMode != null) 'slow_mode': slowMode,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorKey,
    Value<DateTime>? createdAt,
    Value<int>? avatarSkin,
    Value<int>? avatarHair,
    Value<int>? avatarCape,
    Value<int>? avatarHat,
    Value<bool>? storyMode,
    Value<bool>? slowMode,
    Value<DateTime?>? archivedAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      createdAt: createdAt ?? this.createdAt,
      avatarSkin: avatarSkin ?? this.avatarSkin,
      avatarHair: avatarHair ?? this.avatarHair,
      avatarCape: avatarCape ?? this.avatarCape,
      avatarHat: avatarHat ?? this.avatarHat,
      storyMode: storyMode ?? this.storyMode,
      slowMode: slowMode ?? this.slowMode,
      archivedAt: archivedAt ?? this.archivedAt,
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
    if (avatarSkin.present) {
      map['avatar_skin'] = Variable<int>(avatarSkin.value);
    }
    if (avatarHair.present) {
      map['avatar_hair'] = Variable<int>(avatarHair.value);
    }
    if (avatarCape.present) {
      map['avatar_cape'] = Variable<int>(avatarCape.value);
    }
    if (avatarHat.present) {
      map['avatar_hat'] = Variable<int>(avatarHat.value);
    }
    if (storyMode.present) {
      map['story_mode'] = Variable<bool>(storyMode.value);
    }
    if (slowMode.present) {
      map['slow_mode'] = Variable<bool>(slowMode.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarSkin: $avatarSkin, ')
          ..write('avatarHair: $avatarHair, ')
          ..write('avatarCape: $avatarCape, ')
          ..write('avatarHat: $avatarHat, ')
          ..write('storyMode: $storyMode, ')
          ..write('slowMode: $slowMode, ')
          ..write('archivedAt: $archivedAt')
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
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BossFamily?, String> bossFamily =
      GeneratedColumn<String>(
        'boss_family',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BossFamily?>($ChoresTable.$converterbossFamilyn);
  static const VerificationMeta _repeatMonthWeekMeta = const VerificationMeta(
    'repeatMonthWeek',
  );
  @override
  late final GeneratedColumn<int> repeatMonthWeek = GeneratedColumn<int>(
    'repeat_month_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windowDaysMeta = const VerificationMeta(
    'windowDays',
  );
  @override
  late final GeneratedColumn<int> windowDays = GeneratedColumn<int>(
    'window_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _windowFromMeta = const VerificationMeta(
    'windowFrom',
  );
  @override
  late final GeneratedColumn<int> windowFrom = GeneratedColumn<int>(
    'window_from',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windowToMeta = const VerificationMeta(
    'windowTo',
  );
  @override
  late final GeneratedColumn<int> windowTo = GeneratedColumn<int>(
    'window_to',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Assignment, String> assignment =
      GeneratedColumn<String>(
        'assignment',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('anyone'),
      ).withConverter<Assignment>($ChoresTable.$converterassignment);
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
    reminderMinutes,
    bossFamily,
    repeatMonthWeek,
    windowDays,
    windowFrom,
    windowTo,
    assignment,
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
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('repeat_month_week')) {
      context.handle(
        _repeatMonthWeekMeta,
        repeatMonthWeek.isAcceptableOrUnknown(
          data['repeat_month_week']!,
          _repeatMonthWeekMeta,
        ),
      );
    }
    if (data.containsKey('window_days')) {
      context.handle(
        _windowDaysMeta,
        windowDays.isAcceptableOrUnknown(data['window_days']!, _windowDaysMeta),
      );
    }
    if (data.containsKey('window_from')) {
      context.handle(
        _windowFromMeta,
        windowFrom.isAcceptableOrUnknown(data['window_from']!, _windowFromMeta),
      );
    }
    if (data.containsKey('window_to')) {
      context.handle(
        _windowToMeta,
        windowTo.isAcceptableOrUnknown(data['window_to']!, _windowToMeta),
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
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      bossFamily: $ChoresTable.$converterbossFamilyn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}boss_family'],
        ),
      ),
      repeatMonthWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_month_week'],
      ),
      windowDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_days'],
      )!,
      windowFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_from'],
      ),
      windowTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_to'],
      ),
      assignment: $ChoresTable.$converterassignment.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}assignment'],
        )!,
      ),
    );
  }

  @override
  $ChoresTable createAlias(String alias) {
    return $ChoresTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RepeatType, String, String> $converterrepeatType =
      const EnumNameConverter<RepeatType>(RepeatType.values);
  static JsonTypeConverter2<BossFamily, String, String> $converterbossFamily =
      const EnumNameConverter<BossFamily>(BossFamily.values);
  static JsonTypeConverter2<BossFamily?, String?, String?>
  $converterbossFamilyn = JsonTypeConverter2.asNullable($converterbossFamily);
  static JsonTypeConverter2<Assignment, String, String> $converterassignment =
      const EnumNameConverter<Assignment>(Assignment.values);
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

  /// Reminder on due days, as minutes after midnight (schema v3); `null` = off.
  final int? reminderMinutes;

  /// Boss family for fight tokens (schema v4); `null` = the default for the
  /// built-in chore, or the Clutter Imp for user chores.
  final BossFamily? bossFamily;

  /// Monthly on a weekday (schema v8): 1–4 or -1 for the last; `null` =
  /// on the day of the month. See `Recurrence.monthWeek`.
  final int? repeatMonthWeek;

  /// Days each occurrence stays open (schema v8); 0 = until the next one.
  final int windowDays;

  /// Times of day it's meant to be done, as minutes after midnight (schema
  /// v8); both `null` = any time.
  final int? windowFrom;
  final int? windowTo;

  /// Who the chore is for (schema v7); the people are in [ChoreAssignees].
  final Assignment assignment;
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
    this.reminderMinutes,
    this.bossFamily,
    this.repeatMonthWeek,
    required this.windowDays,
    this.windowFrom,
    this.windowTo,
    required this.assignment,
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
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || bossFamily != null) {
      map['boss_family'] = Variable<String>(
        $ChoresTable.$converterbossFamilyn.toSql(bossFamily),
      );
    }
    if (!nullToAbsent || repeatMonthWeek != null) {
      map['repeat_month_week'] = Variable<int>(repeatMonthWeek);
    }
    map['window_days'] = Variable<int>(windowDays);
    if (!nullToAbsent || windowFrom != null) {
      map['window_from'] = Variable<int>(windowFrom);
    }
    if (!nullToAbsent || windowTo != null) {
      map['window_to'] = Variable<int>(windowTo);
    }
    {
      map['assignment'] = Variable<String>(
        $ChoresTable.$converterassignment.toSql(assignment),
      );
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
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      bossFamily: bossFamily == null && nullToAbsent
          ? const Value.absent()
          : Value(bossFamily),
      repeatMonthWeek: repeatMonthWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatMonthWeek),
      windowDays: Value(windowDays),
      windowFrom: windowFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(windowFrom),
      windowTo: windowTo == null && nullToAbsent
          ? const Value.absent()
          : Value(windowTo),
      assignment: Value(assignment),
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
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      bossFamily: $ChoresTable.$converterbossFamilyn.fromJson(
        serializer.fromJson<String?>(json['bossFamily']),
      ),
      repeatMonthWeek: serializer.fromJson<int?>(json['repeatMonthWeek']),
      windowDays: serializer.fromJson<int>(json['windowDays']),
      windowFrom: serializer.fromJson<int?>(json['windowFrom']),
      windowTo: serializer.fromJson<int?>(json['windowTo']),
      assignment: $ChoresTable.$converterassignment.fromJson(
        serializer.fromJson<String>(json['assignment']),
      ),
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
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'bossFamily': serializer.toJson<String?>(
        $ChoresTable.$converterbossFamilyn.toJson(bossFamily),
      ),
      'repeatMonthWeek': serializer.toJson<int?>(repeatMonthWeek),
      'windowDays': serializer.toJson<int>(windowDays),
      'windowFrom': serializer.toJson<int?>(windowFrom),
      'windowTo': serializer.toJson<int?>(windowTo),
      'assignment': serializer.toJson<String>(
        $ChoresTable.$converterassignment.toJson(assignment),
      ),
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
    Value<int?> reminderMinutes = const Value.absent(),
    Value<BossFamily?> bossFamily = const Value.absent(),
    Value<int?> repeatMonthWeek = const Value.absent(),
    int? windowDays,
    Value<int?> windowFrom = const Value.absent(),
    Value<int?> windowTo = const Value.absent(),
    Assignment? assignment,
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
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    bossFamily: bossFamily.present ? bossFamily.value : this.bossFamily,
    repeatMonthWeek: repeatMonthWeek.present
        ? repeatMonthWeek.value
        : this.repeatMonthWeek,
    windowDays: windowDays ?? this.windowDays,
    windowFrom: windowFrom.present ? windowFrom.value : this.windowFrom,
    windowTo: windowTo.present ? windowTo.value : this.windowTo,
    assignment: assignment ?? this.assignment,
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
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      bossFamily: data.bossFamily.present
          ? data.bossFamily.value
          : this.bossFamily,
      repeatMonthWeek: data.repeatMonthWeek.present
          ? data.repeatMonthWeek.value
          : this.repeatMonthWeek,
      windowDays: data.windowDays.present
          ? data.windowDays.value
          : this.windowDays,
      windowFrom: data.windowFrom.present
          ? data.windowFrom.value
          : this.windowFrom,
      windowTo: data.windowTo.present ? data.windowTo.value : this.windowTo,
      assignment: data.assignment.present
          ? data.assignment.value
          : this.assignment,
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
          ..write('repeatSetAt: $repeatSetAt, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('bossFamily: $bossFamily, ')
          ..write('repeatMonthWeek: $repeatMonthWeek, ')
          ..write('windowDays: $windowDays, ')
          ..write('windowFrom: $windowFrom, ')
          ..write('windowTo: $windowTo, ')
          ..write('assignment: $assignment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    reminderMinutes,
    bossFamily,
    repeatMonthWeek,
    windowDays,
    windowFrom,
    windowTo,
    assignment,
  ]);
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
          other.repeatSetAt == this.repeatSetAt &&
          other.reminderMinutes == this.reminderMinutes &&
          other.bossFamily == this.bossFamily &&
          other.repeatMonthWeek == this.repeatMonthWeek &&
          other.windowDays == this.windowDays &&
          other.windowFrom == this.windowFrom &&
          other.windowTo == this.windowTo &&
          other.assignment == this.assignment);
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
  final Value<int?> reminderMinutes;
  final Value<BossFamily?> bossFamily;
  final Value<int?> repeatMonthWeek;
  final Value<int> windowDays;
  final Value<int?> windowFrom;
  final Value<int?> windowTo;
  final Value<Assignment> assignment;
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
    this.reminderMinutes = const Value.absent(),
    this.bossFamily = const Value.absent(),
    this.repeatMonthWeek = const Value.absent(),
    this.windowDays = const Value.absent(),
    this.windowFrom = const Value.absent(),
    this.windowTo = const Value.absent(),
    this.assignment = const Value.absent(),
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
    this.reminderMinutes = const Value.absent(),
    this.bossFamily = const Value.absent(),
    this.repeatMonthWeek = const Value.absent(),
    this.windowDays = const Value.absent(),
    this.windowFrom = const Value.absent(),
    this.windowTo = const Value.absent(),
    this.assignment = const Value.absent(),
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
    Expression<int>? reminderMinutes,
    Expression<String>? bossFamily,
    Expression<int>? repeatMonthWeek,
    Expression<int>? windowDays,
    Expression<int>? windowFrom,
    Expression<int>? windowTo,
    Expression<String>? assignment,
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
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (bossFamily != null) 'boss_family': bossFamily,
      if (repeatMonthWeek != null) 'repeat_month_week': repeatMonthWeek,
      if (windowDays != null) 'window_days': windowDays,
      if (windowFrom != null) 'window_from': windowFrom,
      if (windowTo != null) 'window_to': windowTo,
      if (assignment != null) 'assignment': assignment,
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
    Value<int?>? reminderMinutes,
    Value<BossFamily?>? bossFamily,
    Value<int?>? repeatMonthWeek,
    Value<int>? windowDays,
    Value<int?>? windowFrom,
    Value<int?>? windowTo,
    Value<Assignment>? assignment,
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
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      bossFamily: bossFamily ?? this.bossFamily,
      repeatMonthWeek: repeatMonthWeek ?? this.repeatMonthWeek,
      windowDays: windowDays ?? this.windowDays,
      windowFrom: windowFrom ?? this.windowFrom,
      windowTo: windowTo ?? this.windowTo,
      assignment: assignment ?? this.assignment,
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
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (bossFamily.present) {
      map['boss_family'] = Variable<String>(
        $ChoresTable.$converterbossFamilyn.toSql(bossFamily.value),
      );
    }
    if (repeatMonthWeek.present) {
      map['repeat_month_week'] = Variable<int>(repeatMonthWeek.value);
    }
    if (windowDays.present) {
      map['window_days'] = Variable<int>(windowDays.value);
    }
    if (windowFrom.present) {
      map['window_from'] = Variable<int>(windowFrom.value);
    }
    if (windowTo.present) {
      map['window_to'] = Variable<int>(windowTo.value);
    }
    if (assignment.present) {
      map['assignment'] = Variable<String>(
        $ChoresTable.$converterassignment.toSql(assignment.value),
      );
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
          ..write('repeatSetAt: $repeatSetAt, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('bossFamily: $bossFamily, ')
          ..write('repeatMonthWeek: $repeatMonthWeek, ')
          ..write('windowDays: $windowDays, ')
          ..write('windowFrom: $windowFrom, ')
          ..write('windowTo: $windowTo, ')
          ..write('assignment: $assignment')
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

class $FightsTable extends Fights with TableInfo<$FightsTable, Fight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FightsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<BossFamily, String> family =
      GeneratedColumn<String>(
        'family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BossFamily>($FightsTable.$converterfamily);
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<int> tier = GeneratedColumn<int>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storyModeMeta = const VerificationMeta(
    'storyMode',
  );
  @override
  late final GeneratedColumn<bool> storyMode = GeneratedColumn<bool>(
    'story_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("story_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FightResult?, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<FightResult?>($FightsTable.$converterresultn);
  static const VerificationMeta _perfectMeta = const VerificationMeta(
    'perfect',
  );
  @override
  late final GeneratedColumn<int> perfect = GeneratedColumn<int>(
    'perfect',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _goodMeta = const VerificationMeta('good');
  @override
  late final GeneratedColumn<int> good = GeneratedColumn<int>(
    'good',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missMeta = const VerificationMeta('miss');
  @override
  late final GeneratedColumn<int> miss = GeneratedColumn<int>(
    'miss',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    family,
    tier,
    storyMode,
    startedAt,
    endedAt,
    result,
    perfect,
    good,
    miss,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fight> instance, {
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
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('story_mode')) {
      context.handle(
        _storyModeMeta,
        storyMode.isAcceptableOrUnknown(data['story_mode']!, _storyModeMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('perfect')) {
      context.handle(
        _perfectMeta,
        perfect.isAcceptableOrUnknown(data['perfect']!, _perfectMeta),
      );
    }
    if (data.containsKey('good')) {
      context.handle(
        _goodMeta,
        good.isAcceptableOrUnknown(data['good']!, _goodMeta),
      );
    }
    if (data.containsKey('miss')) {
      context.handle(
        _missMeta,
        miss.isAcceptableOrUnknown(data['miss']!, _missMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      family: $FightsTable.$converterfamily.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}family'],
        )!,
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tier'],
      )!,
      storyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}story_mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      result: $FightsTable.$converterresultn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        ),
      ),
      perfect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}perfect'],
      )!,
      good: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}good'],
      )!,
      miss: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}miss'],
      )!,
    );
  }

  @override
  $FightsTable createAlias(String alias) {
    return $FightsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BossFamily, String, String> $converterfamily =
      const EnumNameConverter<BossFamily>(BossFamily.values);
  static JsonTypeConverter2<FightResult, String, String> $converterresult =
      const EnumNameConverter<FightResult>(FightResult.values);
  static JsonTypeConverter2<FightResult?, String?, String?> $converterresultn =
      JsonTypeConverter2.asNullable($converterresult);
}

class Fight extends DataClass implements Insertable<Fight> {
  final int id;
  final int profileId;
  final BossFamily family;
  final int tier;
  final bool storyMode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FightResult? result;
  final int perfect;
  final int good;
  final int miss;
  const Fight({
    required this.id,
    required this.profileId,
    required this.family,
    required this.tier,
    required this.storyMode,
    required this.startedAt,
    this.endedAt,
    this.result,
    required this.perfect,
    required this.good,
    required this.miss,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    {
      map['family'] = Variable<String>(
        $FightsTable.$converterfamily.toSql(family),
      );
    }
    map['tier'] = Variable<int>(tier);
    map['story_mode'] = Variable<bool>(storyMode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(
        $FightsTable.$converterresultn.toSql(result),
      );
    }
    map['perfect'] = Variable<int>(perfect);
    map['good'] = Variable<int>(good);
    map['miss'] = Variable<int>(miss);
    return map;
  }

  FightsCompanion toCompanion(bool nullToAbsent) {
    return FightsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      family: Value(family),
      tier: Value(tier),
      storyMode: Value(storyMode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      perfect: Value(perfect),
      good: Value(good),
      miss: Value(miss),
    );
  }

  factory Fight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fight(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      family: $FightsTable.$converterfamily.fromJson(
        serializer.fromJson<String>(json['family']),
      ),
      tier: serializer.fromJson<int>(json['tier']),
      storyMode: serializer.fromJson<bool>(json['storyMode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      result: $FightsTable.$converterresultn.fromJson(
        serializer.fromJson<String?>(json['result']),
      ),
      perfect: serializer.fromJson<int>(json['perfect']),
      good: serializer.fromJson<int>(json['good']),
      miss: serializer.fromJson<int>(json['miss']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'family': serializer.toJson<String>(
        $FightsTable.$converterfamily.toJson(family),
      ),
      'tier': serializer.toJson<int>(tier),
      'storyMode': serializer.toJson<bool>(storyMode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'result': serializer.toJson<String?>(
        $FightsTable.$converterresultn.toJson(result),
      ),
      'perfect': serializer.toJson<int>(perfect),
      'good': serializer.toJson<int>(good),
      'miss': serializer.toJson<int>(miss),
    };
  }

  Fight copyWith({
    int? id,
    int? profileId,
    BossFamily? family,
    int? tier,
    bool? storyMode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<FightResult?> result = const Value.absent(),
    int? perfect,
    int? good,
    int? miss,
  }) => Fight(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    family: family ?? this.family,
    tier: tier ?? this.tier,
    storyMode: storyMode ?? this.storyMode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    result: result.present ? result.value : this.result,
    perfect: perfect ?? this.perfect,
    good: good ?? this.good,
    miss: miss ?? this.miss,
  );
  Fight copyWithCompanion(FightsCompanion data) {
    return Fight(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      family: data.family.present ? data.family.value : this.family,
      tier: data.tier.present ? data.tier.value : this.tier,
      storyMode: data.storyMode.present ? data.storyMode.value : this.storyMode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      result: data.result.present ? data.result.value : this.result,
      perfect: data.perfect.present ? data.perfect.value : this.perfect,
      good: data.good.present ? data.good.value : this.good,
      miss: data.miss.present ? data.miss.value : this.miss,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fight(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('family: $family, ')
          ..write('tier: $tier, ')
          ..write('storyMode: $storyMode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('result: $result, ')
          ..write('perfect: $perfect, ')
          ..write('good: $good, ')
          ..write('miss: $miss')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    family,
    tier,
    storyMode,
    startedAt,
    endedAt,
    result,
    perfect,
    good,
    miss,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fight &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.family == this.family &&
          other.tier == this.tier &&
          other.storyMode == this.storyMode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.result == this.result &&
          other.perfect == this.perfect &&
          other.good == this.good &&
          other.miss == this.miss);
}

class FightsCompanion extends UpdateCompanion<Fight> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<BossFamily> family;
  final Value<int> tier;
  final Value<bool> storyMode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<FightResult?> result;
  final Value<int> perfect;
  final Value<int> good;
  final Value<int> miss;
  const FightsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.family = const Value.absent(),
    this.tier = const Value.absent(),
    this.storyMode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.result = const Value.absent(),
    this.perfect = const Value.absent(),
    this.good = const Value.absent(),
    this.miss = const Value.absent(),
  });
  FightsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required BossFamily family,
    required int tier,
    this.storyMode = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.result = const Value.absent(),
    this.perfect = const Value.absent(),
    this.good = const Value.absent(),
    this.miss = const Value.absent(),
  }) : profileId = Value(profileId),
       family = Value(family),
       tier = Value(tier),
       startedAt = Value(startedAt);
  static Insertable<Fight> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? family,
    Expression<int>? tier,
    Expression<bool>? storyMode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? result,
    Expression<int>? perfect,
    Expression<int>? good,
    Expression<int>? miss,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (family != null) 'family': family,
      if (tier != null) 'tier': tier,
      if (storyMode != null) 'story_mode': storyMode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (result != null) 'result': result,
      if (perfect != null) 'perfect': perfect,
      if (good != null) 'good': good,
      if (miss != null) 'miss': miss,
    });
  }

  FightsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<BossFamily>? family,
    Value<int>? tier,
    Value<bool>? storyMode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<FightResult?>? result,
    Value<int>? perfect,
    Value<int>? good,
    Value<int>? miss,
  }) {
    return FightsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      family: family ?? this.family,
      tier: tier ?? this.tier,
      storyMode: storyMode ?? this.storyMode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      result: result ?? this.result,
      perfect: perfect ?? this.perfect,
      good: good ?? this.good,
      miss: miss ?? this.miss,
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
    if (family.present) {
      map['family'] = Variable<String>(
        $FightsTable.$converterfamily.toSql(family.value),
      );
    }
    if (tier.present) {
      map['tier'] = Variable<int>(tier.value);
    }
    if (storyMode.present) {
      map['story_mode'] = Variable<bool>(storyMode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $FightsTable.$converterresultn.toSql(result.value),
      );
    }
    if (perfect.present) {
      map['perfect'] = Variable<int>(perfect.value);
    }
    if (good.present) {
      map['good'] = Variable<int>(good.value);
    }
    if (miss.present) {
      map['miss'] = Variable<int>(miss.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FightsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('family: $family, ')
          ..write('tier: $tier, ')
          ..write('storyMode: $storyMode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('result: $result, ')
          ..write('perfect: $perfect, ')
          ..write('good: $good, ')
          ..write('miss: $miss')
          ..write(')'))
        .toString();
  }
}

class $InventoryTable extends Inventory
    with TableInfo<$InventoryTable, InventoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [profileId, itemKey, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, itemKey};
  @override
  InventoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryEntry(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $InventoryTable createAlias(String alias) {
    return $InventoryTable(attachedDatabase, alias);
  }
}

class InventoryEntry extends DataClass implements Insertable<InventoryEntry> {
  final int profileId;
  final String itemKey;
  final int count;
  const InventoryEntry({
    required this.profileId,
    required this.itemKey,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['item_key'] = Variable<String>(itemKey);
    map['count'] = Variable<int>(count);
    return map;
  }

  InventoryCompanion toCompanion(bool nullToAbsent) {
    return InventoryCompanion(
      profileId: Value(profileId),
      itemKey: Value(itemKey),
      count: Value(count),
    );
  }

  factory InventoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryEntry(
      profileId: serializer.fromJson<int>(json['profileId']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'itemKey': serializer.toJson<String>(itemKey),
      'count': serializer.toJson<int>(count),
    };
  }

  InventoryEntry copyWith({int? profileId, String? itemKey, int? count}) =>
      InventoryEntry(
        profileId: profileId ?? this.profileId,
        itemKey: itemKey ?? this.itemKey,
        count: count ?? this.count,
      );
  InventoryEntry copyWithCompanion(InventoryCompanion data) {
    return InventoryEntry(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryEntry(')
          ..write('profileId: $profileId, ')
          ..write('itemKey: $itemKey, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, itemKey, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryEntry &&
          other.profileId == this.profileId &&
          other.itemKey == this.itemKey &&
          other.count == this.count);
}

class InventoryCompanion extends UpdateCompanion<InventoryEntry> {
  final Value<int> profileId;
  final Value<String> itemKey;
  final Value<int> count;
  final Value<int> rowid;
  const InventoryCompanion({
    this.profileId = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryCompanion.insert({
    required int profileId,
    required String itemKey,
    required int count,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       itemKey = Value(itemKey),
       count = Value(count);
  static Insertable<InventoryEntry> custom({
    Expression<int>? profileId,
    Expression<String>? itemKey,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (itemKey != null) 'item_key': itemKey,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryCompanion copyWith({
    Value<int>? profileId,
    Value<String>? itemKey,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return InventoryCompanion(
      profileId: profileId ?? this.profileId,
      itemKey: itemKey ?? this.itemKey,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCompanion(')
          ..write('profileId: $profileId, ')
          ..write('itemKey: $itemKey, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScreenDaysTable extends ScreenDays
    with TableInfo<$ScreenDaysTable, ScreenDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScreenDaysTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMinutesMeta = const VerificationMeta(
    'usedMinutes',
  );
  @override
  late final GeneratedColumn<int> usedMinutes = GeneratedColumn<int>(
    'used_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _budgetMinutesMeta = const VerificationMeta(
    'budgetMinutes',
  );
  @override
  late final GeneratedColumn<int> budgetMinutes = GeneratedColumn<int>(
    'budget_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voucherMinutesMeta = const VerificationMeta(
    'voucherMinutes',
  );
  @override
  late final GeneratedColumn<int> voucherMinutes = GeneratedColumn<int>(
    'voucher_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    day,
    usedMinutes,
    budgetMinutes,
    voucherMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'screen_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScreenDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('used_minutes')) {
      context.handle(
        _usedMinutesMeta,
        usedMinutes.isAcceptableOrUnknown(
          data['used_minutes']!,
          _usedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('budget_minutes')) {
      context.handle(
        _budgetMinutesMeta,
        budgetMinutes.isAcceptableOrUnknown(
          data['budget_minutes']!,
          _budgetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('voucher_minutes')) {
      context.handle(
        _voucherMinutesMeta,
        voucherMinutes.isAcceptableOrUnknown(
          data['voucher_minutes']!,
          _voucherMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId, day};
  @override
  ScreenDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScreenDay(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      usedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_minutes'],
      )!,
      budgetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_minutes'],
      )!,
      voucherMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voucher_minutes'],
      )!,
    );
  }

  @override
  $ScreenDaysTable createAlias(String alias) {
    return $ScreenDaysTable(attachedDatabase, alias);
  }
}

class ScreenDay extends DataClass implements Insertable<ScreenDay> {
  final int profileId;

  /// Local midnight of the day.
  final DateTime day;

  /// Foreground minutes of the chosen apps (last known for today).
  final int usedMinutes;

  /// The day's whole budget: base + earned by quests + vouchers.
  final int budgetMinutes;

  /// Minutes added by vouchers that day (part of [budgetMinutes]).
  final int voucherMinutes;
  const ScreenDay({
    required this.profileId,
    required this.day,
    required this.usedMinutes,
    required this.budgetMinutes,
    required this.voucherMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['day'] = Variable<DateTime>(day);
    map['used_minutes'] = Variable<int>(usedMinutes);
    map['budget_minutes'] = Variable<int>(budgetMinutes);
    map['voucher_minutes'] = Variable<int>(voucherMinutes);
    return map;
  }

  ScreenDaysCompanion toCompanion(bool nullToAbsent) {
    return ScreenDaysCompanion(
      profileId: Value(profileId),
      day: Value(day),
      usedMinutes: Value(usedMinutes),
      budgetMinutes: Value(budgetMinutes),
      voucherMinutes: Value(voucherMinutes),
    );
  }

  factory ScreenDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScreenDay(
      profileId: serializer.fromJson<int>(json['profileId']),
      day: serializer.fromJson<DateTime>(json['day']),
      usedMinutes: serializer.fromJson<int>(json['usedMinutes']),
      budgetMinutes: serializer.fromJson<int>(json['budgetMinutes']),
      voucherMinutes: serializer.fromJson<int>(json['voucherMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'day': serializer.toJson<DateTime>(day),
      'usedMinutes': serializer.toJson<int>(usedMinutes),
      'budgetMinutes': serializer.toJson<int>(budgetMinutes),
      'voucherMinutes': serializer.toJson<int>(voucherMinutes),
    };
  }

  ScreenDay copyWith({
    int? profileId,
    DateTime? day,
    int? usedMinutes,
    int? budgetMinutes,
    int? voucherMinutes,
  }) => ScreenDay(
    profileId: profileId ?? this.profileId,
    day: day ?? this.day,
    usedMinutes: usedMinutes ?? this.usedMinutes,
    budgetMinutes: budgetMinutes ?? this.budgetMinutes,
    voucherMinutes: voucherMinutes ?? this.voucherMinutes,
  );
  ScreenDay copyWithCompanion(ScreenDaysCompanion data) {
    return ScreenDay(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      day: data.day.present ? data.day.value : this.day,
      usedMinutes: data.usedMinutes.present
          ? data.usedMinutes.value
          : this.usedMinutes,
      budgetMinutes: data.budgetMinutes.present
          ? data.budgetMinutes.value
          : this.budgetMinutes,
      voucherMinutes: data.voucherMinutes.present
          ? data.voucherMinutes.value
          : this.voucherMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScreenDay(')
          ..write('profileId: $profileId, ')
          ..write('day: $day, ')
          ..write('usedMinutes: $usedMinutes, ')
          ..write('budgetMinutes: $budgetMinutes, ')
          ..write('voucherMinutes: $voucherMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(profileId, day, usedMinutes, budgetMinutes, voucherMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScreenDay &&
          other.profileId == this.profileId &&
          other.day == this.day &&
          other.usedMinutes == this.usedMinutes &&
          other.budgetMinutes == this.budgetMinutes &&
          other.voucherMinutes == this.voucherMinutes);
}

class ScreenDaysCompanion extends UpdateCompanion<ScreenDay> {
  final Value<int> profileId;
  final Value<DateTime> day;
  final Value<int> usedMinutes;
  final Value<int> budgetMinutes;
  final Value<int> voucherMinutes;
  final Value<int> rowid;
  const ScreenDaysCompanion({
    this.profileId = const Value.absent(),
    this.day = const Value.absent(),
    this.usedMinutes = const Value.absent(),
    this.budgetMinutes = const Value.absent(),
    this.voucherMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScreenDaysCompanion.insert({
    required int profileId,
    required DateTime day,
    this.usedMinutes = const Value.absent(),
    this.budgetMinutes = const Value.absent(),
    this.voucherMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       day = Value(day);
  static Insertable<ScreenDay> custom({
    Expression<int>? profileId,
    Expression<DateTime>? day,
    Expression<int>? usedMinutes,
    Expression<int>? budgetMinutes,
    Expression<int>? voucherMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (day != null) 'day': day,
      if (usedMinutes != null) 'used_minutes': usedMinutes,
      if (budgetMinutes != null) 'budget_minutes': budgetMinutes,
      if (voucherMinutes != null) 'voucher_minutes': voucherMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScreenDaysCompanion copyWith({
    Value<int>? profileId,
    Value<DateTime>? day,
    Value<int>? usedMinutes,
    Value<int>? budgetMinutes,
    Value<int>? voucherMinutes,
    Value<int>? rowid,
  }) {
    return ScreenDaysCompanion(
      profileId: profileId ?? this.profileId,
      day: day ?? this.day,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      budgetMinutes: budgetMinutes ?? this.budgetMinutes,
      voucherMinutes: voucherMinutes ?? this.voucherMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (usedMinutes.present) {
      map['used_minutes'] = Variable<int>(usedMinutes.value);
    }
    if (budgetMinutes.present) {
      map['budget_minutes'] = Variable<int>(budgetMinutes.value);
    }
    if (voucherMinutes.present) {
      map['voucher_minutes'] = Variable<int>(voucherMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScreenDaysCompanion(')
          ..write('profileId: $profileId, ')
          ..write('day: $day, ')
          ..write('usedMinutes: $usedMinutes, ')
          ..write('budgetMinutes: $budgetMinutes, ')
          ..write('voucherMinutes: $voucherMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChoreAssigneesTable extends ChoreAssignees
    with TableInfo<$ChoreAssigneesTable, ChoreAssignee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoreAssigneesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [choreId, profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chore_assignees';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoreAssignee> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {choreId, profileId};
  @override
  ChoreAssignee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoreAssignee(
      choreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chore_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $ChoreAssigneesTable createAlias(String alias) {
    return $ChoreAssigneesTable(attachedDatabase, alias);
  }
}

class ChoreAssignee extends DataClass implements Insertable<ChoreAssignee> {
  final int choreId;
  final int profileId;
  const ChoreAssignee({required this.choreId, required this.profileId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chore_id'] = Variable<int>(choreId);
    map['profile_id'] = Variable<int>(profileId);
    return map;
  }

  ChoreAssigneesCompanion toCompanion(bool nullToAbsent) {
    return ChoreAssigneesCompanion(
      choreId: Value(choreId),
      profileId: Value(profileId),
    );
  }

  factory ChoreAssignee.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoreAssignee(
      choreId: serializer.fromJson<int>(json['choreId']),
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'choreId': serializer.toJson<int>(choreId),
      'profileId': serializer.toJson<int>(profileId),
    };
  }

  ChoreAssignee copyWith({int? choreId, int? profileId}) => ChoreAssignee(
    choreId: choreId ?? this.choreId,
    profileId: profileId ?? this.profileId,
  );
  ChoreAssignee copyWithCompanion(ChoreAssigneesCompanion data) {
    return ChoreAssignee(
      choreId: data.choreId.present ? data.choreId.value : this.choreId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoreAssignee(')
          ..write('choreId: $choreId, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(choreId, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoreAssignee &&
          other.choreId == this.choreId &&
          other.profileId == this.profileId);
}

class ChoreAssigneesCompanion extends UpdateCompanion<ChoreAssignee> {
  final Value<int> choreId;
  final Value<int> profileId;
  final Value<int> rowid;
  const ChoreAssigneesCompanion({
    this.choreId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChoreAssigneesCompanion.insert({
    required int choreId,
    required int profileId,
    this.rowid = const Value.absent(),
  }) : choreId = Value(choreId),
       profileId = Value(profileId);
  static Insertable<ChoreAssignee> custom({
    Expression<int>? choreId,
    Expression<int>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (choreId != null) 'chore_id': choreId,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChoreAssigneesCompanion copyWith({
    Value<int>? choreId,
    Value<int>? profileId,
    Value<int>? rowid,
  }) {
    return ChoreAssigneesCompanion(
      choreId: choreId ?? this.choreId,
      profileId: profileId ?? this.profileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (choreId.present) {
      map['chore_id'] = Variable<int>(choreId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoreAssigneesCompanion(')
          ..write('choreId: $choreId, ')
          ..write('profileId: $profileId, ')
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
  late final $FightsTable fights = $FightsTable(this);
  late final $InventoryTable inventory = $InventoryTable(this);
  late final $ScreenDaysTable screenDays = $ScreenDaysTable(this);
  late final $ChoreAssigneesTable choreAssignees = $ChoreAssigneesTable(this);
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
    fights,
    inventory,
    screenDays,
    choreAssignees,
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
  Value<int> avatarSkin,
  Value<int> avatarHair,
  Value<int> avatarCape,
  Value<int> avatarHat,
  Value<bool> storyMode,
  Value<bool> slowMode,
  Value<DateTime?> archivedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> colorKey,
  Value<DateTime> createdAt,
  Value<int> avatarSkin,
  Value<int> avatarHair,
  Value<int> avatarCape,
  Value<int> avatarHat,
  Value<bool> storyMode,
  Value<bool> slowMode,
  Value<DateTime?> archivedAt,
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

  static MultiTypedResultKey<$FightsTable, List<Fight>> _fightsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.fights,
    aliasName: 'profiles__id__fights__profile_id',
  );

  $$FightsTableProcessedTableManager get fightsRefs {
    final manager = $$FightsTableTableManager(
      $_db,
      $_db.fights,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InventoryTable, List<InventoryEntry>>
  _inventoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventory,
    aliasName: 'profiles__id__inventory__profile_id',
  );

  $$InventoryTableProcessedTableManager get inventoryRefs {
    final manager = $$InventoryTableTableManager(
      $_db,
      $_db.inventory,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScreenDaysTable, List<ScreenDay>>
  _screenDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.screenDays,
    aliasName: 'profiles__id__screen_days__profile_id',
  );

  $$ScreenDaysTableProcessedTableManager get screenDaysRefs {
    final manager = $$ScreenDaysTableTableManager(
      $_db,
      $_db.screenDays,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_screenDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChoreAssigneesTable, List<ChoreAssignee>>
  _choreAssigneesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.choreAssignees,
    aliasName: 'profiles__id__chore_assignees__profile_id',
  );

  $$ChoreAssigneesTableProcessedTableManager get choreAssigneesRefs {
    final manager = $$ChoreAssigneesTableTableManager(
      $_db,
      $_db.choreAssignees,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_choreAssigneesRefsTable($_db));
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

  ColumnFilters<int> get avatarSkin => $composableBuilder(
    column: $table.avatarSkin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarHair => $composableBuilder(
    column: $table.avatarHair,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarCape => $composableBuilder(
    column: $table.avatarCape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarHat => $composableBuilder(
    column: $table.avatarHat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get storyMode => $composableBuilder(
    column: $table.storyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get slowMode => $composableBuilder(
    column: $table.slowMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
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

  Expression<bool> fightsRefs(
    Expression<bool> Function($$FightsTableFilterComposer f) f,
  ) {
    final $$FightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fights,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FightsTableFilterComposer(
            $db: $db,
            $table: $db.fights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inventoryRefs(
    Expression<bool> Function($$InventoryTableFilterComposer f) f,
  ) {
    final $$InventoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventory,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryTableFilterComposer(
            $db: $db,
            $table: $db.inventory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> screenDaysRefs(
    Expression<bool> Function($$ScreenDaysTableFilterComposer f) f,
  ) {
    final $$ScreenDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.screenDays,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenDaysTableFilterComposer(
            $db: $db,
            $table: $db.screenDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> choreAssigneesRefs(
    Expression<bool> Function($$ChoreAssigneesTableFilterComposer f) f,
  ) {
    final $$ChoreAssigneesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreAssignees,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreAssigneesTableFilterComposer(
            $db: $db,
            $table: $db.choreAssignees,
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

  ColumnOrderings<int> get avatarSkin => $composableBuilder(
    column: $table.avatarSkin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarHair => $composableBuilder(
    column: $table.avatarHair,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarCape => $composableBuilder(
    column: $table.avatarCape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarHat => $composableBuilder(
    column: $table.avatarHat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get storyMode => $composableBuilder(
    column: $table.storyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get slowMode => $composableBuilder(
    column: $table.slowMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
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

  GeneratedColumn<int> get avatarSkin => $composableBuilder(
    column: $table.avatarSkin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarHair => $composableBuilder(
    column: $table.avatarHair,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarCape => $composableBuilder(
    column: $table.avatarCape,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarHat =>
      $composableBuilder(column: $table.avatarHat, builder: (column) => column);

  GeneratedColumn<bool> get storyMode =>
      $composableBuilder(column: $table.storyMode, builder: (column) => column);

  GeneratedColumn<bool> get slowMode =>
      $composableBuilder(column: $table.slowMode, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

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

  Expression<T> fightsRefs<T extends Object>(
    Expression<T> Function($$FightsTableAnnotationComposer a) f,
  ) {
    final $$FightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fights,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FightsTableAnnotationComposer(
            $db: $db,
            $table: $db.fights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inventoryRefs<T extends Object>(
    Expression<T> Function($$InventoryTableAnnotationComposer a) f,
  ) {
    final $$InventoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventory,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryTableAnnotationComposer(
            $db: $db,
            $table: $db.inventory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> screenDaysRefs<T extends Object>(
    Expression<T> Function($$ScreenDaysTableAnnotationComposer a) f,
  ) {
    final $$ScreenDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.screenDays,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.screenDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> choreAssigneesRefs<T extends Object>(
    Expression<T> Function($$ChoreAssigneesTableAnnotationComposer a) f,
  ) {
    final $$ChoreAssigneesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreAssignees,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreAssigneesTableAnnotationComposer(
            $db: $db,
            $table: $db.choreAssignees,
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
          PrefetchHooks Function({
            bool completionsRefs,
            bool pointLedgerRefs,
            bool fightsRefs,
            bool inventoryRefs,
            bool screenDaysRefs,
            bool choreAssigneesRefs,
          })
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
                Value<int> avatarSkin = const Value.absent(),
                Value<int> avatarHair = const Value.absent(),
                Value<int> avatarCape = const Value.absent(),
                Value<int> avatarHat = const Value.absent(),
                Value<bool> storyMode = const Value.absent(),
                Value<bool> slowMode = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                colorKey: colorKey,
                createdAt: createdAt,
                avatarSkin: avatarSkin,
                avatarHair: avatarHair,
                avatarCape: avatarCape,
                avatarHat: avatarHat,
                storyMode: storyMode,
                slowMode: slowMode,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> colorKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> avatarSkin = const Value.absent(),
                Value<int> avatarHair = const Value.absent(),
                Value<int> avatarCape = const Value.absent(),
                Value<int> avatarHat = const Value.absent(),
                Value<bool> storyMode = const Value.absent(),
                Value<bool> slowMode = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                colorKey: colorKey,
                createdAt: createdAt,
                avatarSkin: avatarSkin,
                avatarHair: avatarHair,
                avatarCape: avatarCape,
                avatarHat: avatarHat,
                storyMode: storyMode,
                slowMode: slowMode,
                archivedAt: archivedAt,
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
              ({
                completionsRefs = false,
                pointLedgerRefs = false,
                fightsRefs = false,
                inventoryRefs = false,
                screenDaysRefs = false,
                choreAssigneesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionsRefs) db.completions,
                    if (pointLedgerRefs) db.pointLedger,
                    if (fightsRefs) db.fights,
                    if (inventoryRefs) db.inventory,
                    if (screenDaysRefs) db.screenDays,
                    if (choreAssigneesRefs) db.choreAssignees,
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
                      if (fightsRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          Fight,
                          $FightsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._fightsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).fightsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'profile_id',
                          typedResults: items,
                        ),
                      if (inventoryRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          InventoryEntry,
                          $InventoryTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._inventoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).inventoryRefs,
                          currentColumn: 'id',
                          referencedColumn: 'profile_id',
                          typedResults: items,
                        ),
                      if (screenDaysRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          ScreenDay,
                          $ScreenDaysTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._screenDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).screenDaysRefs,
                          currentColumn: 'id',
                          referencedColumn: 'profile_id',
                          typedResults: items,
                        ),
                      if (choreAssigneesRefs)
                        await $_getPrefetchedDataByColumns<
                          Profile,
                          $ProfilesTable,
                          ChoreAssignee,
                          $ChoreAssigneesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProfilesTableReferences
                              ._choreAssigneesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).choreAssigneesRefs,
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
      PrefetchHooks Function({
        bool completionsRefs,
        bool pointLedgerRefs,
        bool fightsRefs,
        bool inventoryRefs,
        bool screenDaysRefs,
        bool choreAssigneesRefs,
      })
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
  Value<int?> reminderMinutes,
  Value<BossFamily?> bossFamily,
  Value<int?> repeatMonthWeek,
  Value<int> windowDays,
  Value<int?> windowFrom,
  Value<int?> windowTo,
  Value<Assignment> assignment,
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
  Value<int?> reminderMinutes,
  Value<BossFamily?> bossFamily,
  Value<int?> repeatMonthWeek,
  Value<int> windowDays,
  Value<int?> windowFrom,
  Value<int?> windowTo,
  Value<Assignment> assignment,
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

  static MultiTypedResultKey<$ChoreAssigneesTable, List<ChoreAssignee>>
  _choreAssigneesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.choreAssignees,
    aliasName: 'chores__id__chore_assignees__chore_id',
  );

  $$ChoreAssigneesTableProcessedTableManager get choreAssigneesRefs {
    final manager = $$ChoreAssigneesTableTableManager(
      $_db,
      $_db.choreAssignees,
    ).filter((f) => f.choreId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_choreAssigneesRefsTable($_db));
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

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BossFamily?, BossFamily, String>
  get bossFamily => $composableBuilder(
    column: $table.bossFamily,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get repeatMonthWeek => $composableBuilder(
    column: $table.repeatMonthWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowFrom => $composableBuilder(
    column: $table.windowFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowTo => $composableBuilder(
    column: $table.windowTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Assignment, Assignment, String>
  get assignment => $composableBuilder(
    column: $table.assignment,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  Expression<bool> choreAssigneesRefs(
    Expression<bool> Function($$ChoreAssigneesTableFilterComposer f) f,
  ) {
    final $$ChoreAssigneesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreAssignees,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreAssigneesTableFilterComposer(
            $db: $db,
            $table: $db.choreAssignees,
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

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bossFamily => $composableBuilder(
    column: $table.bossFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMonthWeek => $composableBuilder(
    column: $table.repeatMonthWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowFrom => $composableBuilder(
    column: $table.windowFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowTo => $composableBuilder(
    column: $table.windowTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignment => $composableBuilder(
    column: $table.assignment,
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

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BossFamily?, String> get bossFamily =>
      $composableBuilder(
        column: $table.bossFamily,
        builder: (column) => column,
      );

  GeneratedColumn<int> get repeatMonthWeek => $composableBuilder(
    column: $table.repeatMonthWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowDays => $composableBuilder(
    column: $table.windowDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowFrom => $composableBuilder(
    column: $table.windowFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowTo =>
      $composableBuilder(column: $table.windowTo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Assignment, String> get assignment =>
      $composableBuilder(
        column: $table.assignment,
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

  Expression<T> choreAssigneesRefs<T extends Object>(
    Expression<T> Function($$ChoreAssigneesTableAnnotationComposer a) f,
  ) {
    final $$ChoreAssigneesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.choreAssignees,
      getReferencedColumn: (t) => t.choreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChoreAssigneesTableAnnotationComposer(
            $db: $db,
            $table: $db.choreAssignees,
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
          PrefetchHooks Function({
            bool completionsRefs,
            bool choreAssigneesRefs,
          })
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
                Value<int?> reminderMinutes = const Value.absent(),
                Value<BossFamily?> bossFamily = const Value.absent(),
                Value<int?> repeatMonthWeek = const Value.absent(),
                Value<int> windowDays = const Value.absent(),
                Value<int?> windowFrom = const Value.absent(),
                Value<int?> windowTo = const Value.absent(),
                Value<Assignment> assignment = const Value.absent(),
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
                reminderMinutes: reminderMinutes,
                bossFamily: bossFamily,
                repeatMonthWeek: repeatMonthWeek,
                windowDays: windowDays,
                windowFrom: windowFrom,
                windowTo: windowTo,
                assignment: assignment,
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
                Value<int?> reminderMinutes = const Value.absent(),
                Value<BossFamily?> bossFamily = const Value.absent(),
                Value<int?> repeatMonthWeek = const Value.absent(),
                Value<int> windowDays = const Value.absent(),
                Value<int?> windowFrom = const Value.absent(),
                Value<int?> windowTo = const Value.absent(),
                Value<Assignment> assignment = const Value.absent(),
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
                reminderMinutes: reminderMinutes,
                bossFamily: bossFamily,
                repeatMonthWeek: repeatMonthWeek,
                windowDays: windowDays,
                windowFrom: windowFrom,
                windowTo: windowTo,
                assignment: assignment,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChoresTable, Chore>(table),
                  $$ChoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({completionsRefs = false, choreAssigneesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionsRefs) db.completions,
                    if (choreAssigneesRefs) db.choreAssignees,
                  ],
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
                          managerFromTypedResult: (p0) =>
                              $$ChoresTableReferences(
                                db,
                                table,
                                p0,
                              ).completionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'chore_id',
                          typedResults: items,
                        ),
                      if (choreAssigneesRefs)
                        await $_getPrefetchedDataByColumns<
                          Chore,
                          $ChoresTable,
                          ChoreAssignee,
                          $ChoreAssigneesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ChoresTableReferences
                              ._choreAssigneesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChoresTableReferences(
                                db,
                                table,
                                p0,
                              ).choreAssigneesRefs,
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
      PrefetchHooks Function({bool completionsRefs, bool choreAssigneesRefs})
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
typedef $$FightsTableCreateCompanionBuilder = FightsCompanion Function({
  Value<int> id,
  required int profileId,
  required BossFamily family,
  required int tier,
  Value<bool> storyMode,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<FightResult?> result,
  Value<int> perfect,
  Value<int> good,
  Value<int> miss,
});
typedef $$FightsTableUpdateCompanionBuilder = FightsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<BossFamily> family,
  Value<int> tier,
  Value<bool> storyMode,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<FightResult?> result,
  Value<int> perfect,
  Value<int> good,
  Value<int> miss,
});

final class $$FightsTableReferences
    extends BaseReferences<_$AppDatabase, $FightsTable, Fight> {
  $$FightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('fights__profile_id__profiles__id');

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
}

class $$FightsTableFilterComposer
    extends Composer<_$AppDatabase, $FightsTable> {
  $$FightsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<BossFamily, BossFamily, String> get family =>
      $composableBuilder(
        column: $table.family,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get storyMode => $composableBuilder(
    column: $table.storyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FightResult?, FightResult, String>
  get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get perfect => $composableBuilder(
    column: $table.perfect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get good => $composableBuilder(
    column: $table.good,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get miss => $composableBuilder(
    column: $table.miss,
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
}

class $$FightsTableOrderingComposer
    extends Composer<_$AppDatabase, $FightsTable> {
  $$FightsTableOrderingComposer({
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

  ColumnOrderings<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get storyMode => $composableBuilder(
    column: $table.storyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perfect => $composableBuilder(
    column: $table.perfect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get good => $composableBuilder(
    column: $table.good,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get miss => $composableBuilder(
    column: $table.miss,
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
}

class $$FightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FightsTable> {
  $$FightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BossFamily, String> get family =>
      $composableBuilder(column: $table.family, builder: (column) => column);

  GeneratedColumn<int> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<bool> get storyMode =>
      $composableBuilder(column: $table.storyMode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FightResult?, String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get perfect =>
      $composableBuilder(column: $table.perfect, builder: (column) => column);

  GeneratedColumn<int> get good =>
      $composableBuilder(column: $table.good, builder: (column) => column);

  GeneratedColumn<int> get miss =>
      $composableBuilder(column: $table.miss, builder: (column) => column);

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
}

class $$FightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FightsTable,
          Fight,
          $$FightsTableFilterComposer,
          $$FightsTableOrderingComposer,
          $$FightsTableAnnotationComposer,
          $$FightsTableCreateCompanionBuilder,
          $$FightsTableUpdateCompanionBuilder,
          (Fight, $$FightsTableReferences),
          Fight,
          PrefetchHooks Function({bool profileId})
        > {
  $$FightsTableTableManager(_$AppDatabase db, $FightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<BossFamily> family = const Value.absent(),
                Value<int> tier = const Value.absent(),
                Value<bool> storyMode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<FightResult?> result = const Value.absent(),
                Value<int> perfect = const Value.absent(),
                Value<int> good = const Value.absent(),
                Value<int> miss = const Value.absent(),
              }) => FightsCompanion(
                id: id,
                profileId: profileId,
                family: family,
                tier: tier,
                storyMode: storyMode,
                startedAt: startedAt,
                endedAt: endedAt,
                result: result,
                perfect: perfect,
                good: good,
                miss: miss,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required BossFamily family,
                required int tier,
                Value<bool> storyMode = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<FightResult?> result = const Value.absent(),
                Value<int> perfect = const Value.absent(),
                Value<int> good = const Value.absent(),
                Value<int> miss = const Value.absent(),
              }) => FightsCompanion.insert(
                id: id,
                profileId: profileId,
                family: family,
                tier: tier,
                storyMode: storyMode,
                startedAt: startedAt,
                endedAt: endedAt,
                result: result,
                perfect: perfect,
                good: good,
                miss: miss,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FightsTable, Fight>(table),
                  $$FightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                        referencedTable: $$FightsTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$FightsTableReferences
                            ._profileIdTable(db)
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

typedef $$FightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FightsTable,
      Fight,
      $$FightsTableFilterComposer,
      $$FightsTableOrderingComposer,
      $$FightsTableAnnotationComposer,
      $$FightsTableCreateCompanionBuilder,
      $$FightsTableUpdateCompanionBuilder,
      (Fight, $$FightsTableReferences),
      Fight,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$InventoryTableCreateCompanionBuilder = InventoryCompanion Function({
  required int profileId,
  required String itemKey,
  required int count,
  Value<int> rowid,
});
typedef $$InventoryTableUpdateCompanionBuilder = InventoryCompanion Function({
  Value<int> profileId,
  Value<String> itemKey,
  Value<int> count,
  Value<int> rowid,
});

final class $$InventoryTableReferences
    extends BaseReferences<_$AppDatabase, $InventoryTable, InventoryEntry> {
  $$InventoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('inventory__profile_id__profiles__id');

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
}

class $$InventoryTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
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
}

class $$InventoryTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
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
}

class $$InventoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTable> {
  $$InventoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

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
}

class $$InventoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryTable,
          InventoryEntry,
          $$InventoryTableFilterComposer,
          $$InventoryTableOrderingComposer,
          $$InventoryTableAnnotationComposer,
          $$InventoryTableCreateCompanionBuilder,
          $$InventoryTableUpdateCompanionBuilder,
          (InventoryEntry, $$InventoryTableReferences),
          InventoryEntry,
          PrefetchHooks Function({bool profileId})
        > {
  $$InventoryTableTableManager(_$AppDatabase db, $InventoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryCompanion(
                profileId: profileId,
                itemKey: itemKey,
                count: count,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String itemKey,
                required int count,
                Value<int> rowid = const Value.absent(),
              }) => InventoryCompanion.insert(
                profileId: profileId,
                itemKey: itemKey,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InventoryTable, InventoryEntry>(table),
                  $$InventoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                        referencedTable: $$InventoryTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$InventoryTableReferences
                            ._profileIdTable(db)
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

typedef $$InventoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryTable,
      InventoryEntry,
      $$InventoryTableFilterComposer,
      $$InventoryTableOrderingComposer,
      $$InventoryTableAnnotationComposer,
      $$InventoryTableCreateCompanionBuilder,
      $$InventoryTableUpdateCompanionBuilder,
      (InventoryEntry, $$InventoryTableReferences),
      InventoryEntry,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$ScreenDaysTableCreateCompanionBuilder = ScreenDaysCompanion Function({
  required int profileId,
  required DateTime day,
  Value<int> usedMinutes,
  Value<int> budgetMinutes,
  Value<int> voucherMinutes,
  Value<int> rowid,
});
typedef $$ScreenDaysTableUpdateCompanionBuilder = ScreenDaysCompanion Function({
  Value<int> profileId,
  Value<DateTime> day,
  Value<int> usedMinutes,
  Value<int> budgetMinutes,
  Value<int> voucherMinutes,
  Value<int> rowid,
});

final class $$ScreenDaysTableReferences
    extends BaseReferences<_$AppDatabase, $ScreenDaysTable, ScreenDay> {
  $$ScreenDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('screen_days__profile_id__profiles__id');

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
}

class $$ScreenDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ScreenDaysTable> {
  $$ScreenDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedMinutes => $composableBuilder(
    column: $table.usedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetMinutes => $composableBuilder(
    column: $table.budgetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voucherMinutes => $composableBuilder(
    column: $table.voucherMinutes,
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
}

class $$ScreenDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ScreenDaysTable> {
  $$ScreenDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedMinutes => $composableBuilder(
    column: $table.usedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetMinutes => $composableBuilder(
    column: $table.budgetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voucherMinutes => $composableBuilder(
    column: $table.voucherMinutes,
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
}

class $$ScreenDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScreenDaysTable> {
  $$ScreenDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get usedMinutes => $composableBuilder(
    column: $table.usedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get budgetMinutes => $composableBuilder(
    column: $table.budgetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get voucherMinutes => $composableBuilder(
    column: $table.voucherMinutes,
    builder: (column) => column,
  );

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
}

class $$ScreenDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScreenDaysTable,
          ScreenDay,
          $$ScreenDaysTableFilterComposer,
          $$ScreenDaysTableOrderingComposer,
          $$ScreenDaysTableAnnotationComposer,
          $$ScreenDaysTableCreateCompanionBuilder,
          $$ScreenDaysTableUpdateCompanionBuilder,
          (ScreenDay, $$ScreenDaysTableReferences),
          ScreenDay,
          PrefetchHooks Function({bool profileId})
        > {
  $$ScreenDaysTableTableManager(_$AppDatabase db, $ScreenDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScreenDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScreenDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScreenDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> usedMinutes = const Value.absent(),
                Value<int> budgetMinutes = const Value.absent(),
                Value<int> voucherMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenDaysCompanion(
                profileId: profileId,
                day: day,
                usedMinutes: usedMinutes,
                budgetMinutes: budgetMinutes,
                voucherMinutes: voucherMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required DateTime day,
                Value<int> usedMinutes = const Value.absent(),
                Value<int> budgetMinutes = const Value.absent(),
                Value<int> voucherMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenDaysCompanion.insert(
                profileId: profileId,
                day: day,
                usedMinutes: usedMinutes,
                budgetMinutes: budgetMinutes,
                voucherMinutes: voucherMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScreenDaysTable, ScreenDay>(table),
                  $$ScreenDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
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
                        referencedTable: $$ScreenDaysTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$ScreenDaysTableReferences
                            ._profileIdTable(db)
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

typedef $$ScreenDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScreenDaysTable,
      ScreenDay,
      $$ScreenDaysTableFilterComposer,
      $$ScreenDaysTableOrderingComposer,
      $$ScreenDaysTableAnnotationComposer,
      $$ScreenDaysTableCreateCompanionBuilder,
      $$ScreenDaysTableUpdateCompanionBuilder,
      (ScreenDay, $$ScreenDaysTableReferences),
      ScreenDay,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$ChoreAssigneesTableCreateCompanionBuilder =
    ChoreAssigneesCompanion Function({
      required int choreId,
      required int profileId,
      Value<int> rowid,
    });
typedef $$ChoreAssigneesTableUpdateCompanionBuilder =
    ChoreAssigneesCompanion Function({
      Value<int> choreId,
      Value<int> profileId,
      Value<int> rowid,
    });

final class $$ChoreAssigneesTableReferences
    extends BaseReferences<_$AppDatabase, $ChoreAssigneesTable, ChoreAssignee> {
  $$ChoreAssigneesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChoresTable _choreIdTable(_$AppDatabase db) =>
      db.chores.createAlias('chore_assignees__chore_id__chores__id');

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
      db.profiles.createAlias('chore_assignees__profile_id__profiles__id');

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
}

class $$ChoreAssigneesTableFilterComposer
    extends Composer<_$AppDatabase, $ChoreAssigneesTable> {
  $$ChoreAssigneesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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
}

class $$ChoreAssigneesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChoreAssigneesTable> {
  $$ChoreAssigneesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

class $$ChoreAssigneesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChoreAssigneesTable> {
  $$ChoreAssigneesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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
}

class $$ChoreAssigneesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChoreAssigneesTable,
          ChoreAssignee,
          $$ChoreAssigneesTableFilterComposer,
          $$ChoreAssigneesTableOrderingComposer,
          $$ChoreAssigneesTableAnnotationComposer,
          $$ChoreAssigneesTableCreateCompanionBuilder,
          $$ChoreAssigneesTableUpdateCompanionBuilder,
          (ChoreAssignee, $$ChoreAssigneesTableReferences),
          ChoreAssignee,
          PrefetchHooks Function({bool choreId, bool profileId})
        > {
  $$ChoreAssigneesTableTableManager(
    _$AppDatabase db,
    $ChoreAssigneesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoreAssigneesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoreAssigneesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoreAssigneesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> choreId = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChoreAssigneesCompanion(
                choreId: choreId,
                profileId: profileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int choreId,
                required int profileId,
                Value<int> rowid = const Value.absent(),
              }) => ChoreAssigneesCompanion.insert(
                choreId: choreId,
                profileId: profileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChoreAssigneesTable, ChoreAssignee>(table),
                  $$ChoreAssigneesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({choreId = false, profileId = false}) {
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
                    if (choreId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.choreId,
                        referencedTable: $$ChoreAssigneesTableReferences
                            ._choreIdTable(db),
                        referencedColumn: $$ChoreAssigneesTableReferences
                            ._choreIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$ChoreAssigneesTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$ChoreAssigneesTableReferences
                            ._profileIdTable(db)
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

typedef $$ChoreAssigneesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChoreAssigneesTable,
      ChoreAssignee,
      $$ChoreAssigneesTableFilterComposer,
      $$ChoreAssigneesTableOrderingComposer,
      $$ChoreAssigneesTableAnnotationComposer,
      $$ChoreAssigneesTableCreateCompanionBuilder,
      $$ChoreAssigneesTableUpdateCompanionBuilder,
      (ChoreAssignee, $$ChoreAssigneesTableReferences),
      ChoreAssignee,
      PrefetchHooks Function({bool choreId, bool profileId})
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
  $$FightsTableTableManager get fights =>
      $$FightsTableTableManager(_db, _db.fights);
  $$InventoryTableTableManager get inventory =>
      $$InventoryTableTableManager(_db, _db.inventory);
  $$ScreenDaysTableTableManager get screenDays =>
      $$ScreenDaysTableTableManager(_db, _db.screenDays);
  $$ChoreAssigneesTableTableManager get choreAssignees =>
      $$ChoreAssigneesTableTableManager(_db, _db.choreAssignees);
}
