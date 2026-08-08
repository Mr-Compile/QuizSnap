// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#4CAF50'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    color,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final String name;
  final String? description;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Folder({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color'] = Variable<String>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<String>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<String>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Folder copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Folder(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    color,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#4CAF50'),
  );
  static const VerificationMeta _cardCountMeta = const VerificationMeta(
    'cardCount',
  );
  @override
  late final GeneratedColumn<int> cardCount = GeneratedColumn<int>(
    'card_count',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    folderId,
    color,
    cardCount,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('card_count')) {
      context.handle(
        _cardCountMeta,
        cardCount.isAcceptableOrUnknown(data['card_count']!, _cardCountMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      cardCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  final int id;
  final String name;
  final String? description;
  final int? folderId;
  final String color;
  final int cardCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Deck({
    required this.id,
    required this.name,
    this.description,
    this.folderId,
    required this.color,
    required this.cardCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['color'] = Variable<String>(color);
    map['card_count'] = Variable<int>(cardCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      color: Value(color),
      cardCount: Value(cardCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      color: serializer.fromJson<String>(json['color']),
      cardCount: serializer.fromJson<int>(json['cardCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'folderId': serializer.toJson<int?>(folderId),
      'color': serializer.toJson<String>(color),
      'cardCount': serializer.toJson<int>(cardCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Deck copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> folderId = const Value.absent(),
    String? color,
    int? cardCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    folderId: folderId.present ? folderId.value : this.folderId,
    color: color ?? this.color,
    cardCount: cardCount ?? this.cardCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      color: data.color.present ? data.color.value : this.color,
      cardCount: data.cardCount.present ? data.cardCount.value : this.cardCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('folderId: $folderId, ')
          ..write('color: $color, ')
          ..write('cardCount: $cardCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    folderId,
    color,
    cardCount,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.folderId == this.folderId &&
          other.color == this.color &&
          other.cardCount == this.cardCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> folderId;
  final Value<String> color;
  final Value<int> cardCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.folderId = const Value.absent(),
    this.color = const Value.absent(),
    this.cardCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DecksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.folderId = const Value.absent(),
    this.color = const Value.absent(),
    this.cardCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Deck> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? folderId,
    Expression<String>? color,
    Expression<int>? cardCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (folderId != null) 'folder_id': folderId,
      if (color != null) 'color': color,
      if (cardCount != null) 'card_count': cardCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DecksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? folderId,
    Value<String>? color,
    Value<int>? cardCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      folderId: folderId ?? this.folderId,
      color: color ?? this.color,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (cardCount.present) {
      map['card_count'] = Variable<int>(cardCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('folderId: $folderId, ')
          ..write('color: $color, ')
          ..write('cardCount: $cardCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, Flashcard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    question,
    answer,
    deckId,
    order,
    isFavorite,
    reviewCount,
    correctCount,
    lastReviewedAt,
    nextReviewAt,
    easeFactor,
    interval,
    repetitions,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flashcard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flashcard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flashcard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }
}

class Flashcard extends DataClass implements Insertable<Flashcard> {
  final int id;
  final String question;
  final String answer;
  final int deckId;
  final int order;
  final bool isFavorite;
  final int reviewCount;
  final int correctCount;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.deckId,
    required this.order,
    required this.isFavorite,
    required this.reviewCount,
    required this.correctCount,
    this.lastReviewedAt,
    this.nextReviewAt,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    map['deck_id'] = Variable<int>(deckId);
    map['order'] = Variable<int>(order);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['review_count'] = Variable<int>(reviewCount);
    map['correct_count'] = Variable<int>(correctCount);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval'] = Variable<int>(interval);
    map['repetitions'] = Variable<int>(repetitions);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      question: Value(question),
      answer: Value(answer),
      deckId: Value(deckId),
      order: Value(order),
      isFavorite: Value(isFavorite),
      reviewCount: Value(reviewCount),
      correctCount: Value(correctCount),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      easeFactor: Value(easeFactor),
      interval: Value(interval),
      repetitions: Value(repetitions),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Flashcard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flashcard(
      id: serializer.fromJson<int>(json['id']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      deckId: serializer.fromJson<int>(json['deckId']),
      order: serializer.fromJson<int>(json['order']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      interval: serializer.fromJson<int>(json['interval']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'deckId': serializer.toJson<int>(deckId),
      'order': serializer.toJson<int>(order),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'interval': serializer.toJson<int>(interval),
      'repetitions': serializer.toJson<int>(repetitions),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Flashcard copyWith({
    int? id,
    String? question,
    String? answer,
    int? deckId,
    int? order,
    bool? isFavorite,
    int? reviewCount,
    int? correctCount,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<DateTime?> nextReviewAt = const Value.absent(),
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Flashcard(
    id: id ?? this.id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    deckId: deckId ?? this.deckId,
    order: order ?? this.order,
    isFavorite: isFavorite ?? this.isFavorite,
    reviewCount: reviewCount ?? this.reviewCount,
    correctCount: correctCount ?? this.correctCount,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    easeFactor: easeFactor ?? this.easeFactor,
    interval: interval ?? this.interval,
    repetitions: repetitions ?? this.repetitions,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Flashcard copyWithCompanion(FlashcardsCompanion data) {
    return Flashcard(
      id: data.id.present ? data.id.value : this.id,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      order: data.order.present ? data.order.value : this.order,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      interval: data.interval.present ? data.interval.value : this.interval,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flashcard(')
          ..write('id: $id, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('deckId: $deckId, ')
          ..write('order: $order, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    question,
    answer,
    deckId,
    order,
    isFavorite,
    reviewCount,
    correctCount,
    lastReviewedAt,
    nextReviewAt,
    easeFactor,
    interval,
    repetitions,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flashcard &&
          other.id == this.id &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.deckId == this.deckId &&
          other.order == this.order &&
          other.isFavorite == this.isFavorite &&
          other.reviewCount == this.reviewCount &&
          other.correctCount == this.correctCount &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.nextReviewAt == this.nextReviewAt &&
          other.easeFactor == this.easeFactor &&
          other.interval == this.interval &&
          other.repetitions == this.repetitions &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class FlashcardsCompanion extends UpdateCompanion<Flashcard> {
  final Value<int> id;
  final Value<String> question;
  final Value<String> answer;
  final Value<int> deckId;
  final Value<int> order;
  final Value<bool> isFavorite;
  final Value<int> reviewCount;
  final Value<int> correctCount;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime?> nextReviewAt;
  final Value<double> easeFactor;
  final Value<int> interval;
  final Value<int> repetitions;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.deckId = const Value.absent(),
    this.order = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    this.id = const Value.absent(),
    required String question,
    required String answer,
    required int deckId,
    this.order = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : question = Value(question),
       answer = Value(answer),
       deckId = Value(deckId);
  static Insertable<Flashcard> custom({
    Expression<int>? id,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<int>? deckId,
    Expression<int>? order,
    Expression<bool>? isFavorite,
    Expression<int>? reviewCount,
    Expression<int>? correctCount,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? nextReviewAt,
    Expression<double>? easeFactor,
    Expression<int>? interval,
    Expression<int>? repetitions,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (deckId != null) 'deck_id': deckId,
      if (order != null) 'order': order,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (reviewCount != null) 'review_count': reviewCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (interval != null) 'interval': interval,
      if (repetitions != null) 'repetitions': repetitions,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  FlashcardsCompanion copyWith({
    Value<int>? id,
    Value<String>? question,
    Value<String>? answer,
    Value<int>? deckId,
    Value<int>? order,
    Value<bool>? isFavorite,
    Value<int>? reviewCount,
    Value<int>? correctCount,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime?>? nextReviewAt,
    Value<double>? easeFactor,
    Value<int>? interval,
    Value<int>? repetitions,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      deckId: deckId ?? this.deckId,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('deckId: $deckId, ')
          ..write('order: $order, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#4CAF50'),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
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
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tag copyWith({
    int? id,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FlashcardTagsTable extends FlashcardTags
    with TableInfo<$FlashcardTagsTable, FlashcardTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta(
    'flashcardId',
  );
  @override
  late final GeneratedColumn<int> flashcardId = GeneratedColumn<int>(
    'flashcard_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flashcards (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [flashcardId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('flashcard_id')) {
      context.handle(
        _flashcardIdMeta,
        flashcardId.isAcceptableOrUnknown(
          data['flashcard_id']!,
          _flashcardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {flashcardId, tagId};
  @override
  FlashcardTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardTag(
      flashcardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flashcard_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $FlashcardTagsTable createAlias(String alias) {
    return $FlashcardTagsTable(attachedDatabase, alias);
  }
}

class FlashcardTag extends DataClass implements Insertable<FlashcardTag> {
  final int flashcardId;
  final int tagId;
  const FlashcardTag({required this.flashcardId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['flashcard_id'] = Variable<int>(flashcardId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  FlashcardTagsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardTagsCompanion(
      flashcardId: Value(flashcardId),
      tagId: Value(tagId),
    );
  }

  factory FlashcardTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardTag(
      flashcardId: serializer.fromJson<int>(json['flashcardId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'flashcardId': serializer.toJson<int>(flashcardId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  FlashcardTag copyWith({int? flashcardId, int? tagId}) => FlashcardTag(
    flashcardId: flashcardId ?? this.flashcardId,
    tagId: tagId ?? this.tagId,
  );
  FlashcardTag copyWithCompanion(FlashcardTagsCompanion data) {
    return FlashcardTag(
      flashcardId: data.flashcardId.present
          ? data.flashcardId.value
          : this.flashcardId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardTag(')
          ..write('flashcardId: $flashcardId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(flashcardId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardTag &&
          other.flashcardId == this.flashcardId &&
          other.tagId == this.tagId);
}

class FlashcardTagsCompanion extends UpdateCompanion<FlashcardTag> {
  final Value<int> flashcardId;
  final Value<int> tagId;
  final Value<int> rowid;
  const FlashcardTagsCompanion({
    this.flashcardId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardTagsCompanion.insert({
    required int flashcardId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : flashcardId = Value(flashcardId),
       tagId = Value(tagId);
  static Insertable<FlashcardTag> custom({
    Expression<int>? flashcardId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (flashcardId != null) 'flashcard_id': flashcardId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardTagsCompanion copyWith({
    Value<int>? flashcardId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return FlashcardTagsCompanion(
      flashcardId: flashcardId ?? this.flashcardId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (flashcardId.present) {
      map['flashcard_id'] = Variable<int>(flashcardId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardTagsCompanion(')
          ..write('flashcardId: $flashcardId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudySessionsTable extends StudySessions
    with TableInfo<$StudySessionsTable, StudySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _cardsStudiedMeta = const VerificationMeta(
    'cardsStudied',
  );
  @override
  late final GeneratedColumn<int> cardsStudied = GeneratedColumn<int>(
    'cards_studied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cardsCorrectMeta = const VerificationMeta(
    'cardsCorrect',
  );
  @override
  late final GeneratedColumn<int> cardsCorrect = GeneratedColumn<int>(
    'cards_correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _studyModeMeta = const VerificationMeta(
    'studyMode',
  );
  @override
  late final GeneratedColumn<String> studyMode = GeneratedColumn<String>(
    'study_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('review'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    cardsStudied,
    cardsCorrect,
    durationSeconds,
    studyMode,
    startedAt,
    endedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    }
    if (data.containsKey('cards_studied')) {
      context.handle(
        _cardsStudiedMeta,
        cardsStudied.isAcceptableOrUnknown(
          data['cards_studied']!,
          _cardsStudiedMeta,
        ),
      );
    }
    if (data.containsKey('cards_correct')) {
      context.handle(
        _cardsCorrectMeta,
        cardsCorrect.isAcceptableOrUnknown(
          data['cards_correct']!,
          _cardsCorrectMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('study_mode')) {
      context.handle(
        _studyModeMeta,
        studyMode.isAcceptableOrUnknown(data['study_mode']!, _studyModeMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
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
  StudySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      ),
      cardsStudied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards_studied'],
      )!,
      cardsCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards_correct'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      studyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StudySessionsTable createAlias(String alias) {
    return $StudySessionsTable(attachedDatabase, alias);
  }
}

class StudySession extends DataClass implements Insertable<StudySession> {
  final int id;
  final int? deckId;
  final int cardsStudied;
  final int cardsCorrect;
  final int durationSeconds;
  final String studyMode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  const StudySession({
    required this.id,
    this.deckId,
    required this.cardsStudied,
    required this.cardsCorrect,
    required this.durationSeconds,
    required this.studyMode,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || deckId != null) {
      map['deck_id'] = Variable<int>(deckId);
    }
    map['cards_studied'] = Variable<int>(cardsStudied);
    map['cards_correct'] = Variable<int>(cardsCorrect);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['study_mode'] = Variable<String>(studyMode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudySessionsCompanion toCompanion(bool nullToAbsent) {
    return StudySessionsCompanion(
      id: Value(id),
      deckId: deckId == null && nullToAbsent
          ? const Value.absent()
          : Value(deckId),
      cardsStudied: Value(cardsStudied),
      cardsCorrect: Value(cardsCorrect),
      durationSeconds: Value(durationSeconds),
      studyMode: Value(studyMode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
    );
  }

  factory StudySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySession(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<int?>(json['deckId']),
      cardsStudied: serializer.fromJson<int>(json['cardsStudied']),
      cardsCorrect: serializer.fromJson<int>(json['cardsCorrect']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      studyMode: serializer.fromJson<String>(json['studyMode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<int?>(deckId),
      'cardsStudied': serializer.toJson<int>(cardsStudied),
      'cardsCorrect': serializer.toJson<int>(cardsCorrect),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'studyMode': serializer.toJson<String>(studyMode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudySession copyWith({
    int? id,
    Value<int?> deckId = const Value.absent(),
    int? cardsStudied,
    int? cardsCorrect,
    int? durationSeconds,
    String? studyMode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
  }) => StudySession(
    id: id ?? this.id,
    deckId: deckId.present ? deckId.value : this.deckId,
    cardsStudied: cardsStudied ?? this.cardsStudied,
    cardsCorrect: cardsCorrect ?? this.cardsCorrect,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    studyMode: studyMode ?? this.studyMode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  StudySession copyWithCompanion(StudySessionsCompanion data) {
    return StudySession(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      cardsStudied: data.cardsStudied.present
          ? data.cardsStudied.value
          : this.cardsStudied,
      cardsCorrect: data.cardsCorrect.present
          ? data.cardsCorrect.value
          : this.cardsCorrect,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      studyMode: data.studyMode.present ? data.studyMode.value : this.studyMode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySession(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('cardsStudied: $cardsStudied, ')
          ..write('cardsCorrect: $cardsCorrect, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('studyMode: $studyMode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    cardsStudied,
    cardsCorrect,
    durationSeconds,
    studyMode,
    startedAt,
    endedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySession &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.cardsStudied == this.cardsStudied &&
          other.cardsCorrect == this.cardsCorrect &&
          other.durationSeconds == this.durationSeconds &&
          other.studyMode == this.studyMode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt);
}

class StudySessionsCompanion extends UpdateCompanion<StudySession> {
  final Value<int> id;
  final Value<int?> deckId;
  final Value<int> cardsStudied;
  final Value<int> cardsCorrect;
  final Value<int> durationSeconds;
  final Value<String> studyMode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  const StudySessionsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.cardsStudied = const Value.absent(),
    this.cardsCorrect = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.studyMode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StudySessionsCompanion.insert({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.cardsStudied = const Value.absent(),
    this.cardsCorrect = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.studyMode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<StudySession> custom({
    Expression<int>? id,
    Expression<int>? deckId,
    Expression<int>? cardsStudied,
    Expression<int>? cardsCorrect,
    Expression<int>? durationSeconds,
    Expression<String>? studyMode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (cardsStudied != null) 'cards_studied': cardsStudied,
      if (cardsCorrect != null) 'cards_correct': cardsCorrect,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (studyMode != null) 'study_mode': studyMode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StudySessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? deckId,
    Value<int>? cardsStudied,
    Value<int>? cardsCorrect,
    Value<int>? durationSeconds,
    Value<String>? studyMode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
  }) {
    return StudySessionsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      cardsCorrect: cardsCorrect ?? this.cardsCorrect,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      studyMode: studyMode ?? this.studyMode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (cardsStudied.present) {
      map['cards_studied'] = Variable<int>(cardsStudied.value);
    }
    if (cardsCorrect.present) {
      map['cards_correct'] = Variable<int>(cardsCorrect.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (studyMode.present) {
      map['study_mode'] = Variable<String>(studyMode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('cardsStudied: $cardsStudied, ')
          ..write('cardsCorrect: $cardsCorrect, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('studyMode: $studyMode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuizResultsTable extends QuizResults
    with TableInfo<$QuizResultsTable, QuizResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizResultsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctAnswersMeta = const VerificationMeta(
    'correctAnswers',
  );
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
    'correct_answers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quizTypeMeta = const VerificationMeta(
    'quizType',
  );
  @override
  late final GeneratedColumn<String> quizType = GeneratedColumn<String>(
    'quiz_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('practice'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    totalQuestions,
    correctAnswers,
    score,
    durationSeconds,
    quizType,
    completedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
        _correctAnswersMeta,
        correctAnswers.isAcceptableOrUnknown(
          data['correct_answers']!,
          _correctAnswersMeta,
        ),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('quiz_type')) {
      context.handle(
        _quizTypeMeta,
        quizType.isAcceptableOrUnknown(data['quiz_type']!, _quizTypeMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
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
  QuizResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      ),
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correctAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_answers'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      quizType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quiz_type'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuizResultsTable createAlias(String alias) {
    return $QuizResultsTable(attachedDatabase, alias);
  }
}

class QuizResult extends DataClass implements Insertable<QuizResult> {
  final int id;
  final int? deckId;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final int durationSeconds;
  final String quizType;
  final DateTime completedAt;
  final DateTime createdAt;
  const QuizResult({
    required this.id,
    this.deckId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.durationSeconds,
    required this.quizType,
    required this.completedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || deckId != null) {
      map['deck_id'] = Variable<int>(deckId);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_answers'] = Variable<int>(correctAnswers);
    map['score'] = Variable<double>(score);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['quiz_type'] = Variable<String>(quizType);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuizResultsCompanion toCompanion(bool nullToAbsent) {
    return QuizResultsCompanion(
      id: Value(id),
      deckId: deckId == null && nullToAbsent
          ? const Value.absent()
          : Value(deckId),
      totalQuestions: Value(totalQuestions),
      correctAnswers: Value(correctAnswers),
      score: Value(score),
      durationSeconds: Value(durationSeconds),
      quizType: Value(quizType),
      completedAt: Value(completedAt),
      createdAt: Value(createdAt),
    );
  }

  factory QuizResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizResult(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<int?>(json['deckId']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
      score: serializer.fromJson<double>(json['score']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      quizType: serializer.fromJson<String>(json['quizType']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<int?>(deckId),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
      'score': serializer.toJson<double>(score),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'quizType': serializer.toJson<String>(quizType),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuizResult copyWith({
    int? id,
    Value<int?> deckId = const Value.absent(),
    int? totalQuestions,
    int? correctAnswers,
    double? score,
    int? durationSeconds,
    String? quizType,
    DateTime? completedAt,
    DateTime? createdAt,
  }) => QuizResult(
    id: id ?? this.id,
    deckId: deckId.present ? deckId.value : this.deckId,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    score: score ?? this.score,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    quizType: quizType ?? this.quizType,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  QuizResult copyWithCompanion(QuizResultsCompanion data) {
    return QuizResult(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
      score: data.score.present ? data.score.value : this.score,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      quizType: data.quizType.present ? data.quizType.value : this.quizType,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizResult(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('score: $score, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('quizType: $quizType, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    totalQuestions,
    correctAnswers,
    score,
    durationSeconds,
    quizType,
    completedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizResult &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.totalQuestions == this.totalQuestions &&
          other.correctAnswers == this.correctAnswers &&
          other.score == this.score &&
          other.durationSeconds == this.durationSeconds &&
          other.quizType == this.quizType &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class QuizResultsCompanion extends UpdateCompanion<QuizResult> {
  final Value<int> id;
  final Value<int?> deckId;
  final Value<int> totalQuestions;
  final Value<int> correctAnswers;
  final Value<double> score;
  final Value<int> durationSeconds;
  final Value<String> quizType;
  final Value<DateTime> completedAt;
  final Value<DateTime> createdAt;
  const QuizResultsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.score = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.quizType = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuizResultsCompanion.insert({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.score = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.quizType = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<QuizResult> custom({
    Expression<int>? id,
    Expression<int>? deckId,
    Expression<int>? totalQuestions,
    Expression<int>? correctAnswers,
    Expression<double>? score,
    Expression<int>? durationSeconds,
    Expression<String>? quizType,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (score != null) 'score': score,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (quizType != null) 'quiz_type': quizType,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuizResultsCompanion copyWith({
    Value<int>? id,
    Value<int?>? deckId,
    Value<int>? totalQuestions,
    Value<int>? correctAnswers,
    Value<double>? score,
    Value<int>? durationSeconds,
    Value<String>? quizType,
    Value<DateTime>? completedAt,
    Value<DateTime>? createdAt,
  }) {
    return QuizResultsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      score: score ?? this.score,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      quizType: quizType ?? this.quizType,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (quizType.present) {
      map['quiz_type'] = Variable<String>(quizType.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizResultsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('score: $score, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('quizType: $quizType, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AiUsageTable extends AiUsage with TableInfo<$AiUsageTable, AiUsageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiUsageTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedCountMeta = const VerificationMeta(
    'usedCount',
  );
  @override
  late final GeneratedColumn<int> usedCount = GeneratedColumn<int>(
    'used_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dailyLimitMeta = const VerificationMeta(
    'dailyLimit',
  );
  @override
  late final GeneratedColumn<int> dailyLimit = GeneratedColumn<int>(
    'daily_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _lastResetAtMeta = const VerificationMeta(
    'lastResetAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastResetAt = GeneratedColumn<DateTime>(
    'last_reset_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    usedCount,
    dailyLimit,
    lastResetAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_usage';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiUsageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('used_count')) {
      context.handle(
        _usedCountMeta,
        usedCount.isAcceptableOrUnknown(data['used_count']!, _usedCountMeta),
      );
    }
    if (data.containsKey('daily_limit')) {
      context.handle(
        _dailyLimitMeta,
        dailyLimit.isAcceptableOrUnknown(data['daily_limit']!, _dailyLimitMeta),
      );
    }
    if (data.containsKey('last_reset_at')) {
      context.handle(
        _lastResetAtMeta,
        lastResetAt.isAcceptableOrUnknown(
          data['last_reset_at']!,
          _lastResetAtMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiUsageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiUsageData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      usedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_count'],
      )!,
      dailyLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_limit'],
      )!,
      lastResetAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reset_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AiUsageTable createAlias(String alias) {
    return $AiUsageTable(attachedDatabase, alias);
  }
}

class AiUsageData extends DataClass implements Insertable<AiUsageData> {
  final int id;
  final String date;
  final int usedCount;
  final int dailyLimit;
  final DateTime lastResetAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiUsageData({
    required this.id,
    required this.date,
    required this.usedCount,
    required this.dailyLimit,
    required this.lastResetAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['used_count'] = Variable<int>(usedCount);
    map['daily_limit'] = Variable<int>(dailyLimit);
    map['last_reset_at'] = Variable<DateTime>(lastResetAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiUsageCompanion toCompanion(bool nullToAbsent) {
    return AiUsageCompanion(
      id: Value(id),
      date: Value(date),
      usedCount: Value(usedCount),
      dailyLimit: Value(dailyLimit),
      lastResetAt: Value(lastResetAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiUsageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiUsageData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      usedCount: serializer.fromJson<int>(json['usedCount']),
      dailyLimit: serializer.fromJson<int>(json['dailyLimit']),
      lastResetAt: serializer.fromJson<DateTime>(json['lastResetAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'usedCount': serializer.toJson<int>(usedCount),
      'dailyLimit': serializer.toJson<int>(dailyLimit),
      'lastResetAt': serializer.toJson<DateTime>(lastResetAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiUsageData copyWith({
    int? id,
    String? date,
    int? usedCount,
    int? dailyLimit,
    DateTime? lastResetAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AiUsageData(
    id: id ?? this.id,
    date: date ?? this.date,
    usedCount: usedCount ?? this.usedCount,
    dailyLimit: dailyLimit ?? this.dailyLimit,
    lastResetAt: lastResetAt ?? this.lastResetAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiUsageData copyWithCompanion(AiUsageCompanion data) {
    return AiUsageData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      usedCount: data.usedCount.present ? data.usedCount.value : this.usedCount,
      dailyLimit: data.dailyLimit.present
          ? data.dailyLimit.value
          : this.dailyLimit,
      lastResetAt: data.lastResetAt.present
          ? data.lastResetAt.value
          : this.lastResetAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiUsageData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('usedCount: $usedCount, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('lastResetAt: $lastResetAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    usedCount,
    dailyLimit,
    lastResetAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiUsageData &&
          other.id == this.id &&
          other.date == this.date &&
          other.usedCount == this.usedCount &&
          other.dailyLimit == this.dailyLimit &&
          other.lastResetAt == this.lastResetAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiUsageCompanion extends UpdateCompanion<AiUsageData> {
  final Value<int> id;
  final Value<String> date;
  final Value<int> usedCount;
  final Value<int> dailyLimit;
  final Value<DateTime> lastResetAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AiUsageCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.usedCount = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.lastResetAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AiUsageCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.usedCount = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.lastResetAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<AiUsageData> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? usedCount,
    Expression<int>? dailyLimit,
    Expression<DateTime>? lastResetAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (usedCount != null) 'used_count': usedCount,
      if (dailyLimit != null) 'daily_limit': dailyLimit,
      if (lastResetAt != null) 'last_reset_at': lastResetAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AiUsageCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<int>? usedCount,
    Value<int>? dailyLimit,
    Value<DateTime>? lastResetAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AiUsageCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      usedCount: usedCount ?? this.usedCount,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (usedCount.present) {
      map['used_count'] = Variable<int>(usedCount.value);
    }
    if (dailyLimit.present) {
      map['daily_limit'] = Variable<int>(dailyLimit.value);
    }
    if (lastResetAt.present) {
      map['last_reset_at'] = Variable<DateTime>(lastResetAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiUsageCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('usedCount: $usedCount, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('lastResetAt: $lastResetAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExtractedDocumentsTable extends ExtractedDocuments
    with TableInfo<$ExtractedDocumentsTable, ExtractedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtractedDocumentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedScopeMeta = const VerificationMeta(
    'selectedScope',
  );
  @override
  late final GeneratedColumn<String> selectedScope = GeneratedColumn<String>(
    'selected_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _scopeDetailsMeta = const VerificationMeta(
    'scopeDetails',
  );
  @override
  late final GeneratedColumn<String> scopeDetails = GeneratedColumn<String>(
    'scope_details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _characterCountMeta = const VerificationMeta(
    'characterCount',
  );
  @override
  late final GeneratedColumn<int> characterCount = GeneratedColumn<int>(
    'character_count',
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
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileName,
    filePath,
    extractedText,
    selectedScope,
    scopeDetails,
    totalPages,
    characterCount,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extracted_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtractedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extractedTextMeta);
    }
    if (data.containsKey('selected_scope')) {
      context.handle(
        _selectedScopeMeta,
        selectedScope.isAcceptableOrUnknown(
          data['selected_scope']!,
          _selectedScopeMeta,
        ),
      );
    }
    if (data.containsKey('scope_details')) {
      context.handle(
        _scopeDetailsMeta,
        scopeDetails.isAcceptableOrUnknown(
          data['scope_details']!,
          _scopeDetailsMeta,
        ),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('character_count')) {
      context.handle(
        _characterCountMeta,
        characterCount.isAcceptableOrUnknown(
          data['character_count']!,
          _characterCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtractedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtractedDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      )!,
      selectedScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_scope'],
      )!,
      scopeDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_details'],
      ),
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      characterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $ExtractedDocumentsTable createAlias(String alias) {
    return $ExtractedDocumentsTable(attachedDatabase, alias);
  }
}

class ExtractedDocument extends DataClass
    implements Insertable<ExtractedDocument> {
  final int id;
  final String fileName;
  final String filePath;
  final String extractedText;
  final String selectedScope;
  final String? scopeDetails;
  final int totalPages;
  final int characterCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  const ExtractedDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.extractedText,
    required this.selectedScope,
    this.scopeDetails,
    required this.totalPages,
    required this.characterCount,
    required this.createdAt,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['extracted_text'] = Variable<String>(extractedText);
    map['selected_scope'] = Variable<String>(selectedScope);
    if (!nullToAbsent || scopeDetails != null) {
      map['scope_details'] = Variable<String>(scopeDetails);
    }
    map['total_pages'] = Variable<int>(totalPages);
    map['character_count'] = Variable<int>(characterCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  ExtractedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return ExtractedDocumentsCompanion(
      id: Value(id),
      fileName: Value(fileName),
      filePath: Value(filePath),
      extractedText: Value(extractedText),
      selectedScope: Value(selectedScope),
      scopeDetails: scopeDetails == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeDetails),
      totalPages: Value(totalPages),
      characterCount: Value(characterCount),
      createdAt: Value(createdAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory ExtractedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtractedDocument(
      id: serializer.fromJson<int>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      extractedText: serializer.fromJson<String>(json['extractedText']),
      selectedScope: serializer.fromJson<String>(json['selectedScope']),
      scopeDetails: serializer.fromJson<String?>(json['scopeDetails']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      characterCount: serializer.fromJson<int>(json['characterCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'extractedText': serializer.toJson<String>(extractedText),
      'selectedScope': serializer.toJson<String>(selectedScope),
      'scopeDetails': serializer.toJson<String?>(scopeDetails),
      'totalPages': serializer.toJson<int>(totalPages),
      'characterCount': serializer.toJson<int>(characterCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  ExtractedDocument copyWith({
    int? id,
    String? fileName,
    String? filePath,
    String? extractedText,
    String? selectedScope,
    Value<String?> scopeDetails = const Value.absent(),
    int? totalPages,
    int? characterCount,
    DateTime? createdAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => ExtractedDocument(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    filePath: filePath ?? this.filePath,
    extractedText: extractedText ?? this.extractedText,
    selectedScope: selectedScope ?? this.selectedScope,
    scopeDetails: scopeDetails.present ? scopeDetails.value : this.scopeDetails,
    totalPages: totalPages ?? this.totalPages,
    characterCount: characterCount ?? this.characterCount,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  ExtractedDocument copyWithCompanion(ExtractedDocumentsCompanion data) {
    return ExtractedDocument(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      selectedScope: data.selectedScope.present
          ? data.selectedScope.value
          : this.selectedScope,
      scopeDetails: data.scopeDetails.present
          ? data.scopeDetails.value
          : this.scopeDetails,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      characterCount: data.characterCount.present
          ? data.characterCount.value
          : this.characterCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedDocument(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('selectedScope: $selectedScope, ')
          ..write('scopeDetails: $scopeDetails, ')
          ..write('totalPages: $totalPages, ')
          ..write('characterCount: $characterCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileName,
    filePath,
    extractedText,
    selectedScope,
    scopeDetails,
    totalPages,
    characterCount,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtractedDocument &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.extractedText == this.extractedText &&
          other.selectedScope == this.selectedScope &&
          other.scopeDetails == this.scopeDetails &&
          other.totalPages == this.totalPages &&
          other.characterCount == this.characterCount &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class ExtractedDocumentsCompanion extends UpdateCompanion<ExtractedDocument> {
  final Value<int> id;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<String> extractedText;
  final Value<String> selectedScope;
  final Value<String?> scopeDetails;
  final Value<int> totalPages;
  final Value<int> characterCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastUsedAt;
  const ExtractedDocumentsCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.selectedScope = const Value.absent(),
    this.scopeDetails = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.characterCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  ExtractedDocumentsCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    required String filePath,
    required String extractedText,
    this.selectedScope = const Value.absent(),
    this.scopeDetails = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.characterCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  }) : fileName = Value(fileName),
       filePath = Value(filePath),
       extractedText = Value(extractedText);
  static Insertable<ExtractedDocument> custom({
    Expression<int>? id,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<String>? extractedText,
    Expression<String>? selectedScope,
    Expression<String>? scopeDetails,
    Expression<int>? totalPages,
    Expression<int>? characterCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (selectedScope != null) 'selected_scope': selectedScope,
      if (scopeDetails != null) 'scope_details': scopeDetails,
      if (totalPages != null) 'total_pages': totalPages,
      if (characterCount != null) 'character_count': characterCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  ExtractedDocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileName,
    Value<String>? filePath,
    Value<String>? extractedText,
    Value<String>? selectedScope,
    Value<String?>? scopeDetails,
    Value<int>? totalPages,
    Value<int>? characterCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastUsedAt,
  }) {
    return ExtractedDocumentsCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      extractedText: extractedText ?? this.extractedText,
      selectedScope: selectedScope ?? this.selectedScope,
      scopeDetails: scopeDetails ?? this.scopeDetails,
      totalPages: totalPages ?? this.totalPages,
      characterCount: characterCount ?? this.characterCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (selectedScope.present) {
      map['selected_scope'] = Variable<String>(selectedScope.value);
    }
    if (scopeDetails.present) {
      map['scope_details'] = Variable<String>(scopeDetails.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (characterCount.present) {
      map['character_count'] = Variable<int>(characterCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('selectedScope: $selectedScope, ')
          ..write('scopeDetails: $scopeDetails, ')
          ..write('totalPages: $totalPages, ')
          ..write('characterCount: $characterCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $FlashcardTagsTable flashcardTags = $FlashcardTagsTable(this);
  late final $StudySessionsTable studySessions = $StudySessionsTable(this);
  late final $QuizResultsTable quizResults = $QuizResultsTable(this);
  late final $AiUsageTable aiUsage = $AiUsageTable(this);
  late final $ExtractedDocumentsTable extractedDocuments =
      $ExtractedDocumentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folders,
    decks,
    flashcards,
    tags,
    flashcardTags,
    studySessions,
    quizResults,
    aiUsage,
    extractedDocuments,
  ];
}

typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DecksTable, List<Deck>> _decksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.decks,
    aliasName: 'folders__id__decks__folder_id',
  );

  $$DecksTableProcessedTableManager get decksRefs {
    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_decksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> decksRefs(
    Expression<bool> Function($$DecksTableFilterComposer f) f,
  ) {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> decksRefs<T extends Object>(
    Expression<T> Function($$DecksTableAnnotationComposer a) f,
  ) {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool decksRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                name: name,
                description: description,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                name: name,
                description: description,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({decksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (decksRefs) db.decks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (decksRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, Deck>(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences._decksRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$FoldersTableReferences(db, table, p0).decksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool decksRefs})
    >;
typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<int?> folderId,
      Value<String> color,
      Value<int> cardCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<int?> folderId,
      Value<String> color,
      Value<int> cardCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) =>
      db.folders.createAlias('decks__folder_id__folders__id');

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlashcardsTable, List<Flashcard>>
  _flashcardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcards,
    aliasName: 'decks__id__flashcards__deck_id',
  );

  $$FlashcardsTableProcessedTableManager get flashcardsRefs {
    final manager = $$FlashcardsTableTableManager(
      $_db,
      $_db.flashcards,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StudySessionsTable, List<StudySession>>
  _studySessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studySessions,
    aliasName: 'decks__id__study_sessions__deck_id',
  );

  $$StudySessionsTableProcessedTableManager get studySessionsRefs {
    final manager = $$StudySessionsTableTableManager(
      $_db,
      $_db.studySessions,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_studySessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuizResultsTable, List<QuizResult>>
  _quizResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quizResults,
    aliasName: 'decks__id__quiz_results__deck_id',
  );

  $$QuizResultsTableProcessedTableManager get quizResultsRefs {
    final manager = $$QuizResultsTableTableManager(
      $_db,
      $_db.quizResults,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flashcardsRefs(
    Expression<bool> Function($$FlashcardsTableFilterComposer f) f,
  ) {
    final $$FlashcardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableFilterComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> studySessionsRefs(
    Expression<bool> Function($$StudySessionsTableFilterComposer f) f,
  ) {
    final $$StudySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studySessions,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySessionsTableFilterComposer(
            $db: $db,
            $table: $db.studySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> quizResultsRefs(
    Expression<bool> Function($$QuizResultsTableFilterComposer f) f,
  ) {
    final $$QuizResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizResults,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizResultsTableFilterComposer(
            $db: $db,
            $table: $db.quizResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get cardCount =>
      $composableBuilder(column: $table.cardCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flashcardsRefs<T extends Object>(
    Expression<T> Function($$FlashcardsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> studySessionsRefs<T extends Object>(
    Expression<T> Function($$StudySessionsTableAnnotationComposer a) f,
  ) {
    final $$StudySessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studySessions,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.studySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> quizResultsRefs<T extends Object>(
    Expression<T> Function($$QuizResultsTableAnnotationComposer a) f,
  ) {
    final $$QuizResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizResults,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.quizResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({
            bool folderId,
            bool flashcardsRefs,
            bool studySessionsRefs,
            bool quizResultsRefs,
          })
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> cardCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                description: description,
                folderId: folderId,
                color: color,
                cardCount: cardCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> cardCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                description: description,
                folderId: folderId,
                color: color,
                cardCount: cardCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DecksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                flashcardsRefs = false,
                studySessionsRefs = false,
                quizResultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (flashcardsRefs) db.flashcards,
                    if (studySessionsRefs) db.studySessions,
                    if (quizResultsRefs) db.quizResults,
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
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$DecksTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$DecksTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (flashcardsRefs)
                        await $_getPrefetchedData<Deck, $DecksTable, Flashcard>(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._flashcardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).flashcardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (studySessionsRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          StudySession
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._studySessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).studySessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (quizResultsRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          QuizResult
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._quizResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).quizResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({
        bool folderId,
        bool flashcardsRefs,
        bool studySessionsRefs,
        bool quizResultsRefs,
      })
    >;
typedef $$FlashcardsTableCreateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<int> id,
      required String question,
      required String answer,
      required int deckId,
      Value<int> order,
      Value<bool> isFavorite,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextReviewAt,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$FlashcardsTableUpdateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<int> id,
      Value<String> question,
      Value<String> answer,
      Value<int> deckId,
      Value<int> order,
      Value<bool> isFavorite,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextReviewAt,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$FlashcardsTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard> {
  $$FlashcardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('flashcards__deck_id__decks__id');

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<int>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlashcardTagsTable, List<FlashcardTag>>
  _flashcardTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcardTags,
    aliasName: 'flashcards__id__flashcard_tags__flashcard_id',
  );

  $$FlashcardTagsTableProcessedTableManager get flashcardTagsRefs {
    final manager = $$FlashcardTagsTableTableManager(
      $_db,
      $_db.flashcardTags,
    ).filter((f) => f.flashcardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
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

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flashcardTagsRefs(
    Expression<bool> Function($$FlashcardTagsTableFilterComposer f) f,
  ) {
    final $$FlashcardTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardTags,
      getReferencedColumn: (t) => t.flashcardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardTagsTableFilterComposer(
            $db: $db,
            $table: $db.flashcardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
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

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flashcardTagsRefs<T extends Object>(
    Expression<T> Function($$FlashcardTagsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardTags,
      getReferencedColumn: (t) => t.flashcardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          Flashcard,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (Flashcard, $$FlashcardsTableReferences),
          Flashcard,
          PrefetchHooks Function({bool deckId, bool flashcardTagsRefs})
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> question = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<int> deckId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                question: question,
                answer: answer,
                deckId: deckId,
                order: order,
                isFavorite: isFavorite,
                reviewCount: reviewCount,
                correctCount: correctCount,
                lastReviewedAt: lastReviewedAt,
                nextReviewAt: nextReviewAt,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String question,
                required String answer,
                required int deckId,
                Value<int> order = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                question: question,
                answer: answer,
                deckId: deckId,
                order: order,
                isFavorite: isFavorite,
                reviewCount: reviewCount,
                correctCount: correctCount,
                lastReviewedAt: lastReviewedAt,
                nextReviewAt: nextReviewAt,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlashcardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false, flashcardTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (flashcardTagsRefs) db.flashcardTags,
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
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$FlashcardsTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$FlashcardsTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flashcardTagsRefs)
                    await $_getPrefetchedData<
                      Flashcard,
                      $FlashcardsTable,
                      FlashcardTag
                    >(
                      currentTable: table,
                      referencedTable: $$FlashcardsTableReferences
                          ._flashcardTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FlashcardsTableReferences(
                            db,
                            table,
                            p0,
                          ).flashcardTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.flashcardId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      Flashcard,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (Flashcard, $$FlashcardsTableReferences),
      Flashcard,
      PrefetchHooks Function({bool deckId, bool flashcardTagsRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FlashcardTagsTable, List<FlashcardTag>>
  _flashcardTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcardTags,
    aliasName: 'tags__id__flashcard_tags__tag_id',
  );

  $$FlashcardTagsTableProcessedTableManager get flashcardTagsRefs {
    final manager = $$FlashcardTagsTableTableManager(
      $_db,
      $_db.flashcardTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> flashcardTagsRefs(
    Expression<bool> Function($$FlashcardTagsTableFilterComposer f) f,
  ) {
    final $$FlashcardTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardTagsTableFilterComposer(
            $db: $db,
            $table: $db.flashcardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> flashcardTagsRefs<T extends Object>(
    Expression<T> Function($$FlashcardTagsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool flashcardTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({flashcardTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (flashcardTagsRefs) db.flashcardTags,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flashcardTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, FlashcardTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._flashcardTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TagsTableReferences(
                        db,
                        table,
                        p0,
                      ).flashcardTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool flashcardTagsRefs})
    >;
typedef $$FlashcardTagsTableCreateCompanionBuilder =
    FlashcardTagsCompanion Function({
      required int flashcardId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$FlashcardTagsTableUpdateCompanionBuilder =
    FlashcardTagsCompanion Function({
      Value<int> flashcardId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$FlashcardTagsTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardTagsTable, FlashcardTag> {
  $$FlashcardTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlashcardsTable _flashcardIdTable(_$AppDatabase db) =>
      db.flashcards.createAlias('flashcard_tags__flashcard_id__flashcards__id');

  $$FlashcardsTableProcessedTableManager get flashcardId {
    final $_column = $_itemColumn<int>('flashcard_id')!;

    final manager = $$FlashcardsTableTableManager(
      $_db,
      $_db.flashcards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flashcardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('flashcard_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlashcardTagsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardTagsTable> {
  $$FlashcardTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FlashcardsTableFilterComposer get flashcardId {
    final $$FlashcardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flashcardId,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableFilterComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardTagsTable> {
  $$FlashcardTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FlashcardsTableOrderingComposer get flashcardId {
    final $$FlashcardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flashcardId,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableOrderingComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardTagsTable> {
  $$FlashcardTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$FlashcardsTableAnnotationComposer get flashcardId {
    final $$FlashcardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flashcardId,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardTagsTable,
          FlashcardTag,
          $$FlashcardTagsTableFilterComposer,
          $$FlashcardTagsTableOrderingComposer,
          $$FlashcardTagsTableAnnotationComposer,
          $$FlashcardTagsTableCreateCompanionBuilder,
          $$FlashcardTagsTableUpdateCompanionBuilder,
          (FlashcardTag, $$FlashcardTagsTableReferences),
          FlashcardTag,
          PrefetchHooks Function({bool flashcardId, bool tagId})
        > {
  $$FlashcardTagsTableTableManager(_$AppDatabase db, $FlashcardTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> flashcardId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardTagsCompanion(
                flashcardId: flashcardId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int flashcardId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => FlashcardTagsCompanion.insert(
                flashcardId: flashcardId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlashcardTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flashcardId = false, tagId = false}) {
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
                    if (flashcardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.flashcardId,
                                referencedTable: $$FlashcardTagsTableReferences
                                    ._flashcardIdTable(db),
                                referencedColumn: $$FlashcardTagsTableReferences
                                    ._flashcardIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$FlashcardTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$FlashcardTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$FlashcardTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardTagsTable,
      FlashcardTag,
      $$FlashcardTagsTableFilterComposer,
      $$FlashcardTagsTableOrderingComposer,
      $$FlashcardTagsTableAnnotationComposer,
      $$FlashcardTagsTableCreateCompanionBuilder,
      $$FlashcardTagsTableUpdateCompanionBuilder,
      (FlashcardTag, $$FlashcardTagsTableReferences),
      FlashcardTag,
      PrefetchHooks Function({bool flashcardId, bool tagId})
    >;
typedef $$StudySessionsTableCreateCompanionBuilder =
    StudySessionsCompanion Function({
      Value<int> id,
      Value<int?> deckId,
      Value<int> cardsStudied,
      Value<int> cardsCorrect,
      Value<int> durationSeconds,
      Value<String> studyMode,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
    });
typedef $$StudySessionsTableUpdateCompanionBuilder =
    StudySessionsCompanion Function({
      Value<int> id,
      Value<int?> deckId,
      Value<int> cardsStudied,
      Value<int> cardsCorrect,
      Value<int> durationSeconds,
      Value<String> studyMode,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
    });

final class $$StudySessionsTableReferences
    extends BaseReferences<_$AppDatabase, $StudySessionsTable, StudySession> {
  $$StudySessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('study_sessions__deck_id__decks__id');

  $$DecksTableProcessedTableManager? get deckId {
    final $_column = $_itemColumn<int>('deck_id');
    if ($_column == null) return null;
    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StudySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableFilterComposer({
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

  ColumnFilters<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardsCorrect => $composableBuilder(
    column: $table.cardsCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyMode => $composableBuilder(
    column: $table.studyMode,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableOrderingComposer({
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

  ColumnOrderings<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardsCorrect => $composableBuilder(
    column: $table.cardsCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyMode => $composableBuilder(
    column: $table.studyMode,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cardsStudied => $composableBuilder(
    column: $table.cardsStudied,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cardsCorrect => $composableBuilder(
    column: $table.cardsCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studyMode =>
      $composableBuilder(column: $table.studyMode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudySessionsTable,
          StudySession,
          $$StudySessionsTableFilterComposer,
          $$StudySessionsTableOrderingComposer,
          $$StudySessionsTableAnnotationComposer,
          $$StudySessionsTableCreateCompanionBuilder,
          $$StudySessionsTableUpdateCompanionBuilder,
          (StudySession, $$StudySessionsTableReferences),
          StudySession,
          PrefetchHooks Function({bool deckId})
        > {
  $$StudySessionsTableTableManager(_$AppDatabase db, $StudySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deckId = const Value.absent(),
                Value<int> cardsStudied = const Value.absent(),
                Value<int> cardsCorrect = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> studyMode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySessionsCompanion(
                id: id,
                deckId: deckId,
                cardsStudied: cardsStudied,
                cardsCorrect: cardsCorrect,
                durationSeconds: durationSeconds,
                studyMode: studyMode,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deckId = const Value.absent(),
                Value<int> cardsStudied = const Value.absent(),
                Value<int> cardsCorrect = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> studyMode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySessionsCompanion.insert(
                id: id,
                deckId: deckId,
                cardsStudied: cardsStudied,
                cardsCorrect: cardsCorrect,
                durationSeconds: durationSeconds,
                studyMode: studyMode,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudySessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
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
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$StudySessionsTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$StudySessionsTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$StudySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudySessionsTable,
      StudySession,
      $$StudySessionsTableFilterComposer,
      $$StudySessionsTableOrderingComposer,
      $$StudySessionsTableAnnotationComposer,
      $$StudySessionsTableCreateCompanionBuilder,
      $$StudySessionsTableUpdateCompanionBuilder,
      (StudySession, $$StudySessionsTableReferences),
      StudySession,
      PrefetchHooks Function({bool deckId})
    >;
typedef $$QuizResultsTableCreateCompanionBuilder =
    QuizResultsCompanion Function({
      Value<int> id,
      Value<int?> deckId,
      Value<int> totalQuestions,
      Value<int> correctAnswers,
      Value<double> score,
      Value<int> durationSeconds,
      Value<String> quizType,
      Value<DateTime> completedAt,
      Value<DateTime> createdAt,
    });
typedef $$QuizResultsTableUpdateCompanionBuilder =
    QuizResultsCompanion Function({
      Value<int> id,
      Value<int?> deckId,
      Value<int> totalQuestions,
      Value<int> correctAnswers,
      Value<double> score,
      Value<int> durationSeconds,
      Value<String> quizType,
      Value<DateTime> completedAt,
      Value<DateTime> createdAt,
    });

final class $$QuizResultsTableReferences
    extends BaseReferences<_$AppDatabase, $QuizResultsTable, QuizResult> {
  $$QuizResultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('quiz_results__deck_id__decks__id');

  $$DecksTableProcessedTableManager? get deckId {
    final $_column = $_itemColumn<int>('deck_id');
    if ($_column == null) return null;
    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuizResultsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizResultsTable> {
  $$QuizResultsTableFilterComposer({
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

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quizType => $composableBuilder(
    column: $table.quizType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizResultsTable> {
  $$QuizResultsTableOrderingComposer({
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

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quizType => $composableBuilder(
    column: $table.quizType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizResultsTable> {
  $$QuizResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quizType =>
      $composableBuilder(column: $table.quizType, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizResultsTable,
          QuizResult,
          $$QuizResultsTableFilterComposer,
          $$QuizResultsTableOrderingComposer,
          $$QuizResultsTableAnnotationComposer,
          $$QuizResultsTableCreateCompanionBuilder,
          $$QuizResultsTableUpdateCompanionBuilder,
          (QuizResult, $$QuizResultsTableReferences),
          QuizResult,
          PrefetchHooks Function({bool deckId})
        > {
  $$QuizResultsTableTableManager(_$AppDatabase db, $QuizResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deckId = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> quizType = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuizResultsCompanion(
                id: id,
                deckId: deckId,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                score: score,
                durationSeconds: durationSeconds,
                quizType: quizType,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deckId = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> quizType = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuizResultsCompanion.insert(
                id: id,
                deckId: deckId,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                score: score,
                durationSeconds: durationSeconds,
                quizType: quizType,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuizResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
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
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$QuizResultsTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$QuizResultsTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$QuizResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizResultsTable,
      QuizResult,
      $$QuizResultsTableFilterComposer,
      $$QuizResultsTableOrderingComposer,
      $$QuizResultsTableAnnotationComposer,
      $$QuizResultsTableCreateCompanionBuilder,
      $$QuizResultsTableUpdateCompanionBuilder,
      (QuizResult, $$QuizResultsTableReferences),
      QuizResult,
      PrefetchHooks Function({bool deckId})
    >;
typedef $$AiUsageTableCreateCompanionBuilder =
    AiUsageCompanion Function({
      Value<int> id,
      required String date,
      Value<int> usedCount,
      Value<int> dailyLimit,
      Value<DateTime> lastResetAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AiUsageTableUpdateCompanionBuilder =
    AiUsageCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<int> usedCount,
      Value<int> dailyLimit,
      Value<DateTime> lastResetAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AiUsageTableFilterComposer
    extends Composer<_$AppDatabase, $AiUsageTable> {
  $$AiUsageTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedCount => $composableBuilder(
    column: $table.usedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastResetAt => $composableBuilder(
    column: $table.lastResetAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiUsageTableOrderingComposer
    extends Composer<_$AppDatabase, $AiUsageTable> {
  $$AiUsageTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedCount => $composableBuilder(
    column: $table.usedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastResetAt => $composableBuilder(
    column: $table.lastResetAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiUsageTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiUsageTable> {
  $$AiUsageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get usedCount =>
      $composableBuilder(column: $table.usedCount, builder: (column) => column);

  GeneratedColumn<int> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastResetAt => $composableBuilder(
    column: $table.lastResetAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AiUsageTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiUsageTable,
          AiUsageData,
          $$AiUsageTableFilterComposer,
          $$AiUsageTableOrderingComposer,
          $$AiUsageTableAnnotationComposer,
          $$AiUsageTableCreateCompanionBuilder,
          $$AiUsageTableUpdateCompanionBuilder,
          (
            AiUsageData,
            BaseReferences<_$AppDatabase, $AiUsageTable, AiUsageData>,
          ),
          AiUsageData,
          PrefetchHooks Function()
        > {
  $$AiUsageTableTableManager(_$AppDatabase db, $AiUsageTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiUsageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiUsageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiUsageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> usedCount = const Value.absent(),
                Value<int> dailyLimit = const Value.absent(),
                Value<DateTime> lastResetAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AiUsageCompanion(
                id: id,
                date: date,
                usedCount: usedCount,
                dailyLimit: dailyLimit,
                lastResetAt: lastResetAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                Value<int> usedCount = const Value.absent(),
                Value<int> dailyLimit = const Value.absent(),
                Value<DateTime> lastResetAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AiUsageCompanion.insert(
                id: id,
                date: date,
                usedCount: usedCount,
                dailyLimit: dailyLimit,
                lastResetAt: lastResetAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiUsageTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiUsageTable,
      AiUsageData,
      $$AiUsageTableFilterComposer,
      $$AiUsageTableOrderingComposer,
      $$AiUsageTableAnnotationComposer,
      $$AiUsageTableCreateCompanionBuilder,
      $$AiUsageTableUpdateCompanionBuilder,
      (AiUsageData, BaseReferences<_$AppDatabase, $AiUsageTable, AiUsageData>),
      AiUsageData,
      PrefetchHooks Function()
    >;
typedef $$ExtractedDocumentsTableCreateCompanionBuilder =
    ExtractedDocumentsCompanion Function({
      Value<int> id,
      required String fileName,
      required String filePath,
      required String extractedText,
      Value<String> selectedScope,
      Value<String?> scopeDetails,
      Value<int> totalPages,
      Value<int> characterCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastUsedAt,
    });
typedef $$ExtractedDocumentsTableUpdateCompanionBuilder =
    ExtractedDocumentsCompanion Function({
      Value<int> id,
      Value<String> fileName,
      Value<String> filePath,
      Value<String> extractedText,
      Value<String> selectedScope,
      Value<String?> scopeDetails,
      Value<int> totalPages,
      Value<int> characterCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastUsedAt,
    });

class $$ExtractedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $ExtractedDocumentsTable> {
  $$ExtractedDocumentsTableFilterComposer({
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

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedScope => $composableBuilder(
    column: $table.selectedScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeDetails => $composableBuilder(
    column: $table.scopeDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExtractedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtractedDocumentsTable> {
  $$ExtractedDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedScope => $composableBuilder(
    column: $table.selectedScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeDetails => $composableBuilder(
    column: $table.scopeDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExtractedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtractedDocumentsTable> {
  $$ExtractedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedScope => $composableBuilder(
    column: $table.selectedScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scopeDetails => $composableBuilder(
    column: $table.scopeDetails,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ExtractedDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtractedDocumentsTable,
          ExtractedDocument,
          $$ExtractedDocumentsTableFilterComposer,
          $$ExtractedDocumentsTableOrderingComposer,
          $$ExtractedDocumentsTableAnnotationComposer,
          $$ExtractedDocumentsTableCreateCompanionBuilder,
          $$ExtractedDocumentsTableUpdateCompanionBuilder,
          (
            ExtractedDocument,
            BaseReferences<
              _$AppDatabase,
              $ExtractedDocumentsTable,
              ExtractedDocument
            >,
          ),
          ExtractedDocument,
          PrefetchHooks Function()
        > {
  $$ExtractedDocumentsTableTableManager(
    _$AppDatabase db,
    $ExtractedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtractedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtractedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtractedDocumentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> extractedText = const Value.absent(),
                Value<String> selectedScope = const Value.absent(),
                Value<String?> scopeDetails = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<int> characterCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
              }) => ExtractedDocumentsCompanion(
                id: id,
                fileName: fileName,
                filePath: filePath,
                extractedText: extractedText,
                selectedScope: selectedScope,
                scopeDetails: scopeDetails,
                totalPages: totalPages,
                characterCount: characterCount,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileName,
                required String filePath,
                required String extractedText,
                Value<String> selectedScope = const Value.absent(),
                Value<String?> scopeDetails = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<int> characterCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
              }) => ExtractedDocumentsCompanion.insert(
                id: id,
                fileName: fileName,
                filePath: filePath,
                extractedText: extractedText,
                selectedScope: selectedScope,
                scopeDetails: scopeDetails,
                totalPages: totalPages,
                characterCount: characterCount,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtractedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtractedDocumentsTable,
      ExtractedDocument,
      $$ExtractedDocumentsTableFilterComposer,
      $$ExtractedDocumentsTableOrderingComposer,
      $$ExtractedDocumentsTableAnnotationComposer,
      $$ExtractedDocumentsTableCreateCompanionBuilder,
      $$ExtractedDocumentsTableUpdateCompanionBuilder,
      (
        ExtractedDocument,
        BaseReferences<
          _$AppDatabase,
          $ExtractedDocumentsTable,
          ExtractedDocument
        >,
      ),
      ExtractedDocument,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$FlashcardTagsTableTableManager get flashcardTags =>
      $$FlashcardTagsTableTableManager(_db, _db.flashcardTags);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db, _db.studySessions);
  $$QuizResultsTableTableManager get quizResults =>
      $$QuizResultsTableTableManager(_db, _db.quizResults);
  $$AiUsageTableTableManager get aiUsage =>
      $$AiUsageTableTableManager(_db, _db.aiUsage);
  $$ExtractedDocumentsTableTableManager get extractedDocuments =>
      $$ExtractedDocumentsTableTableManager(_db, _db.extractedDocuments);
}
