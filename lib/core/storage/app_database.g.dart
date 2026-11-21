// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, role, fullName, phone, status, locale, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String role;
  final String fullName;
  final String phone;
  final String status;
  final String locale;
  final DateTime updatedAt;
  const User(
      {required this.id,
      required this.role,
      required this.fullName,
      required this.phone,
      required this.status,
      required this.locale,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role'] = Variable<String>(role);
    map['full_name'] = Variable<String>(fullName);
    map['phone'] = Variable<String>(phone);
    map['status'] = Variable<String>(status);
    map['locale'] = Variable<String>(locale);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      role: Value(role),
      fullName: Value(fullName),
      phone: Value(phone),
      status: Value(status),
      locale: Value(locale),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phone: serializer.fromJson<String>(json['phone']),
      status: serializer.fromJson<String>(json['status']),
      locale: serializer.fromJson<String>(json['locale']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'role': serializer.toJson<String>(role),
      'fullName': serializer.toJson<String>(fullName),
      'phone': serializer.toJson<String>(phone),
      'status': serializer.toJson<String>(status),
      'locale': serializer.toJson<String>(locale),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith(
          {String? id,
          String? role,
          String? fullName,
          String? phone,
          String? status,
          String? locale,
          DateTime? updatedAt}) =>
      User(
        id: id ?? this.id,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        locale: locale ?? this.locale,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      status: data.status.present ? data.status.value : this.status,
      locale: data.locale.present ? data.locale.value : this.locale,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('locale: $locale, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, role, fullName, phone, status, locale, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.role == this.role &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.status == this.status &&
          other.locale == this.locale &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> role;
  final Value<String> fullName;
  final Value<String> phone;
  final Value<String> status;
  final Value<String> locale;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.status = const Value.absent(),
    this.locale = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String role,
    required String fullName,
    required String phone,
    required String status,
    required String locale,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        role = Value(role),
        fullName = Value(fullName),
        phone = Value(phone),
        status = Value(status),
        locale = Value(locale),
        updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? role,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<String>? status,
    Expression<String>? locale,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (status != null) 'status': status,
      if (locale != null) 'locale': locale,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? role,
      Value<String>? fullName,
      Value<String>? phone,
      Value<String>? status,
      Value<String>? locale,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      locale: locale ?? this.locale,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('locale: $locale, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderProfilesTable extends ProviderProfiles
    with TableInfo<$ProviderProfilesTable, ProviderProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _municipalityMeta =
      const VerificationMeta('municipality');
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
      'municipality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _departmentMeta =
      const VerificationMeta('department');
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
      'department', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
      'lng', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        displayName,
        municipality,
        department,
        lat,
        lng,
        description,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProviderProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('municipality')) {
      context.handle(
          _municipalityMeta,
          municipality.isAcceptableOrUnknown(
              data['municipality']!, _municipalityMeta));
    } else if (isInserting) {
      context.missing(_municipalityMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
          _departmentMeta,
          department.isAcceptableOrUnknown(
              data['department']!, _departmentMeta));
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
          _lngMeta, lng.isAcceptableOrUnknown(data['lng']!, _lngMeta));
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  ProviderProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderProfile(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      municipality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}municipality'])!,
      department: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}department'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lng'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProviderProfilesTable createAlias(String alias) {
    return $ProviderProfilesTable(attachedDatabase, alias);
  }
}

class ProviderProfile extends DataClass implements Insertable<ProviderProfile> {
  final String userId;
  final String displayName;
  final String municipality;
  final String department;
  final double lat;
  final double lng;
  final String description;
  final DateTime updatedAt;
  const ProviderProfile(
      {required this.userId,
      required this.displayName,
      required this.municipality,
      required this.department,
      required this.lat,
      required this.lng,
      required this.description,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    map['municipality'] = Variable<String>(municipality);
    map['department'] = Variable<String>(department);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['description'] = Variable<String>(description);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProviderProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProviderProfilesCompanion(
      userId: Value(userId),
      displayName: Value(displayName),
      municipality: Value(municipality),
      department: Value(department),
      lat: Value(lat),
      lng: Value(lng),
      description: Value(description),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderProfile(
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      municipality: serializer.fromJson<String>(json['municipality']),
      department: serializer.fromJson<String>(json['department']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      description: serializer.fromJson<String>(json['description']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'municipality': serializer.toJson<String>(municipality),
      'department': serializer.toJson<String>(department),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'description': serializer.toJson<String>(description),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProviderProfile copyWith(
          {String? userId,
          String? displayName,
          String? municipality,
          String? department,
          double? lat,
          double? lng,
          String? description,
          DateTime? updatedAt}) =>
      ProviderProfile(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        municipality: municipality ?? this.municipality,
        department: department ?? this.department,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        description: description ?? this.description,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProviderProfile copyWithCompanion(ProviderProfilesCompanion data) {
    return ProviderProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
      department:
          data.department.present ? data.department.value : this.department,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      description:
          data.description.present ? data.description.value : this.description,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderProfile(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('municipality: $municipality, ')
          ..write('department: $department, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, displayName, municipality, department,
      lat, lng, description, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderProfile &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.municipality == this.municipality &&
          other.department == this.department &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.description == this.description &&
          other.updatedAt == this.updatedAt);
}

class ProviderProfilesCompanion extends UpdateCompanion<ProviderProfile> {
  final Value<String> userId;
  final Value<String> displayName;
  final Value<String> municipality;
  final Value<String> department;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String> description;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProviderProfilesCompanion({
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.municipality = const Value.absent(),
    this.department = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderProfilesCompanion.insert({
    required String userId,
    required String displayName,
    required String municipality,
    required String department,
    required double lat,
    required double lng,
    required String description,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        displayName = Value(displayName),
        municipality = Value(municipality),
        department = Value(department),
        lat = Value(lat),
        lng = Value(lng),
        description = Value(description),
        updatedAt = Value(updatedAt);
  static Insertable<ProviderProfile> custom({
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? municipality,
    Expression<String>? department,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? description,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (municipality != null) 'municipality': municipality,
      if (department != null) 'department': department,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderProfilesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? displayName,
      Value<String>? municipality,
      Value<String>? department,
      Value<double>? lat,
      Value<double>? lng,
      Value<String>? description,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProviderProfilesCompanion(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      municipality: municipality ?? this.municipality,
      department: department ?? this.department,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('municipality: $municipality, ')
          ..write('department: $department, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<int> depth = GeneratedColumn<int>(
      'depth', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId, depth, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('depth')) {
      context.handle(
          _depthMeta, depth.isAcceptableOrUnknown(data['depth']!, _depthMeta));
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      depth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}depth'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String? parentId;
  final int depth;
  final DateTime syncedAt;
  const Category(
      {required this.id,
      required this.name,
      this.parentId,
      required this.depth,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['depth'] = Variable<int>(depth);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      depth: Value(depth),
      syncedAt: Value(syncedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      depth: serializer.fromJson<int>(json['depth']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'depth': serializer.toJson<int>(depth),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Category copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent(),
          int? depth,
          DateTime? syncedAt}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        depth: depth ?? this.depth,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      depth: data.depth.present ? data.depth.value : this.depth,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('depth: $depth, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, depth, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.depth == this.depth &&
          other.syncedAt == this.syncedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> depth;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.depth = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required int depth,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        depth = Value(depth),
        syncedAt = Value(syncedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? depth,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (depth != null) 'depth': depth,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<int>? depth,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      syncedAt: syncedAt ?? this.syncedAt,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (depth.present) {
      map['depth'] = Variable<int>(depth.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
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
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('depth: $depth, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attributesJsonMeta =
      const VerificationMeta('attributesJson');
  @override
  late final GeneratedColumn<String> attributesJson = GeneratedColumn<String>(
      'attributes_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, name, unit, attributesJson, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('attributes_json')) {
      context.handle(
          _attributesJsonMeta,
          attributesJson.isAcceptableOrUnknown(
              data['attributes_json']!, _attributesJsonMeta));
    } else if (isInserting) {
      context.missing(_attributesJsonMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      attributesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attributes_json'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String categoryId;
  final String name;
  final String unit;
  final String attributesJson;
  final DateTime syncedAt;
  const Product(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.unit,
      required this.attributesJson,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['attributes_json'] = Variable<String>(attributesJson);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      unit: Value(unit),
      attributesJson: Value(attributesJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      attributesJson: serializer.fromJson<String>(json['attributesJson']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'attributesJson': serializer.toJson<String>(attributesJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Product copyWith(
          {String? id,
          String? categoryId,
          String? name,
          String? unit,
          String? attributesJson,
          DateTime? syncedAt}) =>
      Product(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        attributesJson: attributesJson ?? this.attributesJson,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      attributesJson: data.attributesJson.present
          ? data.attributesJson.value
          : this.attributesJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, name, unit, attributesJson, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.attributesJson == this.attributesJson &&
          other.syncedAt == this.syncedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String> unit;
  final Value<String> attributesJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    required String unit,
    required String attributesJson,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryId = Value(categoryId),
        name = Value(name),
        unit = Value(unit),
        attributesJson = Value(attributesJson),
        syncedAt = Value(syncedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<String>? attributesJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (attributesJson != null) 'attributes_json': attributesJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryId,
      Value<String>? name,
      Value<String>? unit,
      Value<String>? attributesJson,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      attributesJson: attributesJson ?? this.attributesJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (attributesJson.present) {
      map['attributes_json'] = Variable<String>(attributesJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LotsTable extends Lots with TableInfo<$LotsTable, Lot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMilliMeta =
      const VerificationMeta('quantityMilli');
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
      'quantity_milli', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _qualityGradeMeta =
      const VerificationMeta('qualityGrade');
  @override
  late final GeneratedColumn<String> qualityGrade = GeneratedColumn<String>(
      'quality_grade', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _availableFromMeta =
      const VerificationMeta('availableFrom');
  @override
  late final GeneratedColumn<DateTime> availableFrom =
      GeneratedColumn<DateTime>('available_from', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _availableUntilMeta =
      const VerificationMeta('availableUntil');
  @override
  late final GeneratedColumn<DateTime> availableUntil =
      GeneratedColumn<DateTime>('available_until', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _providerSummaryJsonMeta =
      const VerificationMeta('providerSummaryJson');
  @override
  late final GeneratedColumn<String> providerSummaryJson =
      GeneratedColumn<String>('provider_summary_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _distanceKmMeta =
      const VerificationMeta('distanceKm');
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
      'distance_km', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isMineMeta = const VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
      'is_mine', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mine" IN (0, 1))'));
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        providerId,
        productId,
        quantityMilli,
        unit,
        unitPrice,
        qualityGrade,
        availableFrom,
        availableUntil,
        status,
        version,
        providerSummaryJson,
        distanceKm,
        isMine,
        syncState,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lots';
  @override
  VerificationContext validateIntegrity(Insertable<Lot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
          _quantityMilliMeta,
          quantityMilli.isAcceptableOrUnknown(
              data['quantity_milli']!, _quantityMilliMeta));
    } else if (isInserting) {
      context.missing(_quantityMilliMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('quality_grade')) {
      context.handle(
          _qualityGradeMeta,
          qualityGrade.isAcceptableOrUnknown(
              data['quality_grade']!, _qualityGradeMeta));
    }
    if (data.containsKey('available_from')) {
      context.handle(
          _availableFromMeta,
          availableFrom.isAcceptableOrUnknown(
              data['available_from']!, _availableFromMeta));
    } else if (isInserting) {
      context.missing(_availableFromMeta);
    }
    if (data.containsKey('available_until')) {
      context.handle(
          _availableUntilMeta,
          availableUntil.isAcceptableOrUnknown(
              data['available_until']!, _availableUntilMeta));
    } else if (isInserting) {
      context.missing(_availableUntilMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('provider_summary_json')) {
      context.handle(
          _providerSummaryJsonMeta,
          providerSummaryJson.isAcceptableOrUnknown(
              data['provider_summary_json']!, _providerSummaryJsonMeta));
    }
    if (data.containsKey('distance_km')) {
      context.handle(
          _distanceKmMeta,
          distanceKm.isAcceptableOrUnknown(
              data['distance_km']!, _distanceKmMeta));
    }
    if (data.containsKey('is_mine')) {
      context.handle(_isMineMeta,
          isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta));
    } else if (isInserting) {
      context.missing(_isMineMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      quantityMilli: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity_milli'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_price'])!,
      qualityGrade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality_grade']),
      availableFrom: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}available_from'])!,
      availableUntil: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}available_until'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      providerSummaryJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_summary_json']),
      distanceKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_km']),
      isMine: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mine'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LotsTable createAlias(String alias) {
    return $LotsTable(attachedDatabase, alias);
  }
}

class Lot extends DataClass implements Insertable<Lot> {
  final String id;
  final String providerId;
  final String productId;
  final int quantityMilli;
  final String unit;
  final int unitPrice;
  final String? qualityGrade;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final String status;
  final int version;
  final String? providerSummaryJson;
  final double? distanceKm;
  final bool isMine;
  final String syncState;
  final DateTime updatedAt;
  const Lot(
      {required this.id,
      required this.providerId,
      required this.productId,
      required this.quantityMilli,
      required this.unit,
      required this.unitPrice,
      this.qualityGrade,
      required this.availableFrom,
      required this.availableUntil,
      required this.status,
      required this.version,
      this.providerSummaryJson,
      this.distanceKm,
      required this.isMine,
      required this.syncState,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['product_id'] = Variable<String>(productId);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['unit'] = Variable<String>(unit);
    map['unit_price'] = Variable<int>(unitPrice);
    if (!nullToAbsent || qualityGrade != null) {
      map['quality_grade'] = Variable<String>(qualityGrade);
    }
    map['available_from'] = Variable<DateTime>(availableFrom);
    map['available_until'] = Variable<DateTime>(availableUntil);
    map['status'] = Variable<String>(status);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || providerSummaryJson != null) {
      map['provider_summary_json'] = Variable<String>(providerSummaryJson);
    }
    if (!nullToAbsent || distanceKm != null) {
      map['distance_km'] = Variable<double>(distanceKm);
    }
    map['is_mine'] = Variable<bool>(isMine);
    map['sync_state'] = Variable<String>(syncState);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LotsCompanion toCompanion(bool nullToAbsent) {
    return LotsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      productId: Value(productId),
      quantityMilli: Value(quantityMilli),
      unit: Value(unit),
      unitPrice: Value(unitPrice),
      qualityGrade: qualityGrade == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityGrade),
      availableFrom: Value(availableFrom),
      availableUntil: Value(availableUntil),
      status: Value(status),
      version: Value(version),
      providerSummaryJson: providerSummaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(providerSummaryJson),
      distanceKm: distanceKm == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceKm),
      isMine: Value(isMine),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory Lot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lot(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      productId: serializer.fromJson<String>(json['productId']),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      qualityGrade: serializer.fromJson<String?>(json['qualityGrade']),
      availableFrom: serializer.fromJson<DateTime>(json['availableFrom']),
      availableUntil: serializer.fromJson<DateTime>(json['availableUntil']),
      status: serializer.fromJson<String>(json['status']),
      version: serializer.fromJson<int>(json['version']),
      providerSummaryJson:
          serializer.fromJson<String?>(json['providerSummaryJson']),
      distanceKm: serializer.fromJson<double?>(json['distanceKm']),
      isMine: serializer.fromJson<bool>(json['isMine']),
      syncState: serializer.fromJson<String>(json['syncState']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'productId': serializer.toJson<String>(productId),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'unit': serializer.toJson<String>(unit),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'qualityGrade': serializer.toJson<String?>(qualityGrade),
      'availableFrom': serializer.toJson<DateTime>(availableFrom),
      'availableUntil': serializer.toJson<DateTime>(availableUntil),
      'status': serializer.toJson<String>(status),
      'version': serializer.toJson<int>(version),
      'providerSummaryJson': serializer.toJson<String?>(providerSummaryJson),
      'distanceKm': serializer.toJson<double?>(distanceKm),
      'isMine': serializer.toJson<bool>(isMine),
      'syncState': serializer.toJson<String>(syncState),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Lot copyWith(
          {String? id,
          String? providerId,
          String? productId,
          int? quantityMilli,
          String? unit,
          int? unitPrice,
          Value<String?> qualityGrade = const Value.absent(),
          DateTime? availableFrom,
          DateTime? availableUntil,
          String? status,
          int? version,
          Value<String?> providerSummaryJson = const Value.absent(),
          Value<double?> distanceKm = const Value.absent(),
          bool? isMine,
          String? syncState,
          DateTime? updatedAt}) =>
      Lot(
        id: id ?? this.id,
        providerId: providerId ?? this.providerId,
        productId: productId ?? this.productId,
        quantityMilli: quantityMilli ?? this.quantityMilli,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
        qualityGrade:
            qualityGrade.present ? qualityGrade.value : this.qualityGrade,
        availableFrom: availableFrom ?? this.availableFrom,
        availableUntil: availableUntil ?? this.availableUntil,
        status: status ?? this.status,
        version: version ?? this.version,
        providerSummaryJson: providerSummaryJson.present
            ? providerSummaryJson.value
            : this.providerSummaryJson,
        distanceKm: distanceKm.present ? distanceKm.value : this.distanceKm,
        isMine: isMine ?? this.isMine,
        syncState: syncState ?? this.syncState,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Lot copyWithCompanion(LotsCompanion data) {
    return Lot(
      id: data.id.present ? data.id.value : this.id,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      qualityGrade: data.qualityGrade.present
          ? data.qualityGrade.value
          : this.qualityGrade,
      availableFrom: data.availableFrom.present
          ? data.availableFrom.value
          : this.availableFrom,
      availableUntil: data.availableUntil.present
          ? data.availableUntil.value
          : this.availableUntil,
      status: data.status.present ? data.status.value : this.status,
      version: data.version.present ? data.version.value : this.version,
      providerSummaryJson: data.providerSummaryJson.present
          ? data.providerSummaryJson.value
          : this.providerSummaryJson,
      distanceKm:
          data.distanceKm.present ? data.distanceKm.value : this.distanceKm,
      isMine: data.isMine.present ? data.isMine.value : this.isMine,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lot(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('productId: $productId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('availableFrom: $availableFrom, ')
          ..write('availableUntil: $availableUntil, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('providerSummaryJson: $providerSummaryJson, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('isMine: $isMine, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      providerId,
      productId,
      quantityMilli,
      unit,
      unitPrice,
      qualityGrade,
      availableFrom,
      availableUntil,
      status,
      version,
      providerSummaryJson,
      distanceKm,
      isMine,
      syncState,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lot &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.productId == this.productId &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.qualityGrade == this.qualityGrade &&
          other.availableFrom == this.availableFrom &&
          other.availableUntil == this.availableUntil &&
          other.status == this.status &&
          other.version == this.version &&
          other.providerSummaryJson == this.providerSummaryJson &&
          other.distanceKm == this.distanceKm &&
          other.isMine == this.isMine &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LotsCompanion extends UpdateCompanion<Lot> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> productId;
  final Value<int> quantityMilli;
  final Value<String> unit;
  final Value<int> unitPrice;
  final Value<String?> qualityGrade;
  final Value<DateTime> availableFrom;
  final Value<DateTime> availableUntil;
  final Value<String> status;
  final Value<int> version;
  final Value<String?> providerSummaryJson;
  final Value<double?> distanceKm;
  final Value<bool> isMine;
  final Value<String> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LotsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.qualityGrade = const Value.absent(),
    this.availableFrom = const Value.absent(),
    this.availableUntil = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
    this.providerSummaryJson = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.isMine = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LotsCompanion.insert({
    required String id,
    required String providerId,
    required String productId,
    required int quantityMilli,
    required String unit,
    required int unitPrice,
    this.qualityGrade = const Value.absent(),
    required DateTime availableFrom,
    required DateTime availableUntil,
    required String status,
    required int version,
    this.providerSummaryJson = const Value.absent(),
    this.distanceKm = const Value.absent(),
    required bool isMine,
    required String syncState,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        providerId = Value(providerId),
        productId = Value(productId),
        quantityMilli = Value(quantityMilli),
        unit = Value(unit),
        unitPrice = Value(unitPrice),
        availableFrom = Value(availableFrom),
        availableUntil = Value(availableUntil),
        status = Value(status),
        version = Value(version),
        isMine = Value(isMine),
        syncState = Value(syncState),
        updatedAt = Value(updatedAt);
  static Insertable<Lot> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? productId,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<int>? unitPrice,
    Expression<String>? qualityGrade,
    Expression<DateTime>? availableFrom,
    Expression<DateTime>? availableUntil,
    Expression<String>? status,
    Expression<int>? version,
    Expression<String>? providerSummaryJson,
    Expression<double>? distanceKm,
    Expression<bool>? isMine,
    Expression<String>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (productId != null) 'product_id': productId,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (qualityGrade != null) 'quality_grade': qualityGrade,
      if (availableFrom != null) 'available_from': availableFrom,
      if (availableUntil != null) 'available_until': availableUntil,
      if (status != null) 'status': status,
      if (version != null) 'version': version,
      if (providerSummaryJson != null)
        'provider_summary_json': providerSummaryJson,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (isMine != null) 'is_mine': isMine,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? providerId,
      Value<String>? productId,
      Value<int>? quantityMilli,
      Value<String>? unit,
      Value<int>? unitPrice,
      Value<String?>? qualityGrade,
      Value<DateTime>? availableFrom,
      Value<DateTime>? availableUntil,
      Value<String>? status,
      Value<int>? version,
      Value<String?>? providerSummaryJson,
      Value<double?>? distanceKm,
      Value<bool>? isMine,
      Value<String>? syncState,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LotsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      productId: productId ?? this.productId,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      status: status ?? this.status,
      version: version ?? this.version,
      providerSummaryJson: providerSummaryJson ?? this.providerSummaryJson,
      distanceKm: distanceKm ?? this.distanceKm,
      isMine: isMine ?? this.isMine,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (qualityGrade.present) {
      map['quality_grade'] = Variable<String>(qualityGrade.value);
    }
    if (availableFrom.present) {
      map['available_from'] = Variable<DateTime>(availableFrom.value);
    }
    if (availableUntil.present) {
      map['available_until'] = Variable<DateTime>(availableUntil.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (providerSummaryJson.present) {
      map['provider_summary_json'] =
          Variable<String>(providerSummaryJson.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LotsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('productId: $productId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('availableFrom: $availableFrom, ')
          ..write('availableUntil: $availableUntil, ')
          ..write('status: $status, ')
          ..write('version: $version, ')
          ..write('providerSummaryJson: $providerSummaryJson, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('isMine: $isMine, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxOperationsTable extends OutboxOperations
    with TableInfo<$OutboxOperationsTable, OutboxOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
      'op_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerUserIdMeta =
      const VerificationMeta('ownerUserId');
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
      'owner_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseVersionMeta =
      const VerificationMeta('baseVersion');
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
      'base_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _clientTsMeta =
      const VerificationMeta('clientTs');
  @override
  late final GeneratedColumn<DateTime> clientTs = GeneratedColumn<DateTime>(
      'client_ts', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        opId,
        ownerUserId,
        entity,
        entityId,
        type,
        payloadJson,
        baseVersion,
        clientTs,
        status,
        attempts,
        nextAttemptAt,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_operations';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxOperation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
          _opIdMeta, opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta));
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
          _ownerUserIdMeta,
          ownerUserId.isAcceptableOrUnknown(
              data['owner_user_id']!, _ownerUserIdMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
          _baseVersionMeta,
          baseVersion.isAcceptableOrUnknown(
              data['base_version']!, _baseVersionMeta));
    }
    if (data.containsKey('client_ts')) {
      context.handle(_clientTsMeta,
          clientTs.isAcceptableOrUnknown(data['client_ts']!, _clientTsMeta));
    } else if (isInserting) {
      context.missing(_clientTsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    } else if (isInserting) {
      context.missing(_attemptsMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  OutboxOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOperation(
      opId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_id'])!,
      ownerUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_user_id']),
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      baseVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_version']),
      clientTs: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}client_ts'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $OutboxOperationsTable createAlias(String alias) {
    return $OutboxOperationsTable(attachedDatabase, alias);
  }
}

class OutboxOperation extends DataClass implements Insertable<OutboxOperation> {
  final String opId;
  final String? ownerUserId;
  final String entity;
  final String entityId;
  final String type;
  final String payloadJson;
  final int? baseVersion;
  final DateTime clientTs;
  final String status;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastError;
  const OutboxOperation(
      {required this.opId,
      this.ownerUserId,
      required this.entity,
      required this.entityId,
      required this.type,
      required this.payloadJson,
      this.baseVersion,
      required this.clientTs,
      required this.status,
      required this.attempts,
      required this.nextAttemptAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['client_ts'] = Variable<DateTime>(clientTs);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxOperationsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOperationsCompanion(
      opId: Value(opId),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      entity: Value(entity),
      entityId: Value(entityId),
      type: Value(type),
      payloadJson: Value(payloadJson),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      clientTs: Value(clientTs),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxOperation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOperation(
      opId: serializer.fromJson<String>(json['opId']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      clientTs: serializer.fromJson<DateTime>(json['clientTs']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'clientTs': serializer.toJson<DateTime>(clientTs),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxOperation copyWith(
          {String? opId,
          Value<String?> ownerUserId = const Value.absent(),
          String? entity,
          String? entityId,
          String? type,
          String? payloadJson,
          Value<int?> baseVersion = const Value.absent(),
          DateTime? clientTs,
          String? status,
          int? attempts,
          DateTime? nextAttemptAt,
          Value<String?> lastError = const Value.absent()}) =>
      OutboxOperation(
        opId: opId ?? this.opId,
        ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        type: type ?? this.type,
        payloadJson: payloadJson ?? this.payloadJson,
        baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
        clientTs: clientTs ?? this.clientTs,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  OutboxOperation copyWithCompanion(OutboxOperationsCompanion data) {
    return OutboxOperation(
      opId: data.opId.present ? data.opId.value : this.opId,
      ownerUserId:
          data.ownerUserId.present ? data.ownerUserId.value : this.ownerUserId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      type: data.type.present ? data.type.value : this.type,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      baseVersion:
          data.baseVersion.present ? data.baseVersion.value : this.baseVersion,
      clientTs: data.clientTs.present ? data.clientTs.value : this.clientTs,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperation(')
          ..write('opId: $opId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('clientTs: $clientTs, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      opId,
      ownerUserId,
      entity,
      entityId,
      type,
      payloadJson,
      baseVersion,
      clientTs,
      status,
      attempts,
      nextAttemptAt,
      lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOperation &&
          other.opId == this.opId &&
          other.ownerUserId == this.ownerUserId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.baseVersion == this.baseVersion &&
          other.clientTs == this.clientTs &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class OutboxOperationsCompanion extends UpdateCompanion<OutboxOperation> {
  final Value<String> opId;
  final Value<String?> ownerUserId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<int?> baseVersion;
  final Value<DateTime> clientTs;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxOperationsCompanion({
    this.opId = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.clientTs = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOperationsCompanion.insert({
    required String opId,
    this.ownerUserId = const Value.absent(),
    required String entity,
    required String entityId,
    required String type,
    required String payloadJson,
    this.baseVersion = const Value.absent(),
    required DateTime clientTs,
    required String status,
    required int attempts,
    required DateTime nextAttemptAt,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : opId = Value(opId),
        entity = Value(entity),
        entityId = Value(entityId),
        type = Value(type),
        payloadJson = Value(payloadJson),
        clientTs = Value(clientTs),
        status = Value(status),
        attempts = Value(attempts),
        nextAttemptAt = Value(nextAttemptAt);
  static Insertable<OutboxOperation> custom({
    Expression<String>? opId,
    Expression<String>? ownerUserId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<int>? baseVersion,
    Expression<DateTime>? clientTs,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseVersion != null) 'base_version': baseVersion,
      if (clientTs != null) 'client_ts': clientTs,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOperationsCompanion copyWith(
      {Value<String>? opId,
      Value<String?>? ownerUserId,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? type,
      Value<String>? payloadJson,
      Value<int?>? baseVersion,
      Value<DateTime>? clientTs,
      Value<String>? status,
      Value<int>? attempts,
      Value<DateTime>? nextAttemptAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return OutboxOperationsCompanion(
      opId: opId ?? this.opId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      baseVersion: baseVersion ?? this.baseVersion,
      clientTs: clientTs ?? this.clientTs,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (clientTs.present) {
      map['client_ts'] = Variable<DateTime>(clientTs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOperationsCompanion(')
          ..write('opId: $opId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('clientTs: $clientTs, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
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

  SyncStateData copyWith({String? key, String? value}) => SyncStateData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
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
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncStateData> custom({
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

  SyncStateCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncStateCompanion(
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
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentStateTable extends ConsentState
    with TableInfo<$ConsentStateTable, ConsentStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
      'version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _acceptedAtMeta =
      const VerificationMeta('acceptedAt');
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
      'accepted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [version, acceptedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_state';
  @override
  VerificationContext validateIntegrity(Insertable<ConsentStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
          _acceptedAtMeta,
          acceptedAt.isAcceptableOrUnknown(
              data['accepted_at']!, _acceptedAtMeta));
    } else if (isInserting) {
      context.missing(_acceptedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  ConsentStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentStateData(
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version'])!,
      acceptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}accepted_at'])!,
    );
  }

  @override
  $ConsentStateTable createAlias(String alias) {
    return $ConsentStateTable(attachedDatabase, alias);
  }
}

class ConsentStateData extends DataClass
    implements Insertable<ConsentStateData> {
  final String version;
  final DateTime acceptedAt;
  const ConsentStateData({required this.version, required this.acceptedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<String>(version);
    map['accepted_at'] = Variable<DateTime>(acceptedAt);
    return map;
  }

  ConsentStateCompanion toCompanion(bool nullToAbsent) {
    return ConsentStateCompanion(
      version: Value(version),
      acceptedAt: Value(acceptedAt),
    );
  }

  factory ConsentStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentStateData(
      version: serializer.fromJson<String>(json['version']),
      acceptedAt: serializer.fromJson<DateTime>(json['acceptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<String>(version),
      'acceptedAt': serializer.toJson<DateTime>(acceptedAt),
    };
  }

  ConsentStateData copyWith({String? version, DateTime? acceptedAt}) =>
      ConsentStateData(
        version: version ?? this.version,
        acceptedAt: acceptedAt ?? this.acceptedAt,
      );
  ConsentStateData copyWithCompanion(ConsentStateCompanion data) {
    return ConsentStateData(
      version: data.version.present ? data.version.value : this.version,
      acceptedAt:
          data.acceptedAt.present ? data.acceptedAt.value : this.acceptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentStateData(')
          ..write('version: $version, ')
          ..write('acceptedAt: $acceptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, acceptedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentStateData &&
          other.version == this.version &&
          other.acceptedAt == this.acceptedAt);
}

class ConsentStateCompanion extends UpdateCompanion<ConsentStateData> {
  final Value<String> version;
  final Value<DateTime> acceptedAt;
  final Value<int> rowid;
  const ConsentStateCompanion({
    this.version = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentStateCompanion.insert({
    required String version,
    required DateTime acceptedAt,
    this.rowid = const Value.absent(),
  })  : version = Value(version),
        acceptedAt = Value(acceptedAt);
  static Insertable<ConsentStateData> custom({
    Expression<String>? version,
    Expression<DateTime>? acceptedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentStateCompanion copyWith(
      {Value<String>? version,
      Value<DateTime>? acceptedAt,
      Value<int>? rowid}) {
    return ConsentStateCompanion(
      version: version ?? this.version,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentStateCompanion(')
          ..write('version: $version, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ProviderProfilesTable providerProfiles =
      $ProviderProfilesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $LotsTable lots = $LotsTable(this);
  late final $OutboxOperationsTable outboxOperations =
      $OutboxOperationsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $ConsentStateTable consentState = $ConsentStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        providerProfiles,
        categories,
        products,
        lots,
        outboxOperations,
        syncState,
        consentState
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String role,
  required String fullName,
  required String phone,
  required String status,
  required String locale,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> role,
  Value<String> fullName,
  Value<String> phone,
  Value<String> status,
  Value<String> locale,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            role: role,
            fullName: fullName,
            phone: phone,
            status: status,
            locale: locale,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String role,
            required String fullName,
            required String phone,
            required String status,
            required String locale,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            role: role,
            fullName: fullName,
            phone: phone,
            status: status,
            locale: locale,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$UsersTable, User>(table),
                    BaseReferences<_$AppDatabase, $UsersTable, User>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$ProviderProfilesTableCreateCompanionBuilder
    = ProviderProfilesCompanion Function({
  required String userId,
  required String displayName,
  required String municipality,
  required String department,
  required double lat,
  required double lng,
  required String description,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProviderProfilesTableUpdateCompanionBuilder
    = ProviderProfilesCompanion Function({
  Value<String> userId,
  Value<String> displayName,
  Value<String> municipality,
  Value<String> department,
  Value<double> lat,
  Value<double> lng,
  Value<String> description,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProviderProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProviderProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipality => $composableBuilder(
      column: $table.municipality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProviderProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProviderProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProviderProfilesTable,
    ProviderProfile,
    $$ProviderProfilesTableFilterComposer,
    $$ProviderProfilesTableOrderingComposer,
    $$ProviderProfilesTableAnnotationComposer,
    $$ProviderProfilesTableCreateCompanionBuilder,
    $$ProviderProfilesTableUpdateCompanionBuilder,
    (
      ProviderProfile,
      BaseReferences<_$AppDatabase, $ProviderProfilesTable, ProviderProfile>
    ),
    ProviderProfile,
    PrefetchHooks Function()> {
  $$ProviderProfilesTableTableManager(
      _$AppDatabase db, $ProviderProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> municipality = const Value.absent(),
            Value<String> department = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lng = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderProfilesCompanion(
            userId: userId,
            displayName: displayName,
            municipality: municipality,
            department: department,
            lat: lat,
            lng: lng,
            description: description,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String displayName,
            required String municipality,
            required String department,
            required double lat,
            required double lng,
            required String description,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderProfilesCompanion.insert(
            userId: userId,
            displayName: displayName,
            municipality: municipality,
            department: department,
            lat: lat,
            lng: lng,
            description: description,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProviderProfilesTable, ProviderProfile>(table),
                    BaseReferences<_$AppDatabase, $ProviderProfilesTable,
                        ProviderProfile>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProviderProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProviderProfilesTable,
    ProviderProfile,
    $$ProviderProfilesTableFilterComposer,
    $$ProviderProfilesTableOrderingComposer,
    $$ProviderProfilesTableAnnotationComposer,
    $$ProviderProfilesTableCreateCompanionBuilder,
    $$ProviderProfilesTableUpdateCompanionBuilder,
    (
      ProviderProfile,
      BaseReferences<_$AppDatabase, $ProviderProfilesTable, ProviderProfile>
    ),
    ProviderProfile,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> parentId,
  required int depth,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<int> depth,
  Value<DateTime> syncedAt,
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get depth => $composableBuilder(
      column: $table.depth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get depth => $composableBuilder(
      column: $table.depth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<int> depth = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            parentId: parentId,
            depth: depth,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> parentId = const Value.absent(),
            required int depth,
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            depth: depth,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoriesTable, Category>(table),
                    BaseReferences<_$AppDatabase, $CategoriesTable, Category>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String categoryId,
  required String name,
  required String unit,
  required String attributesJson,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String> name,
  Value<String> unit,
  Value<String> attributesJson,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            categoryId: categoryId,
            name: name,
            unit: unit,
            attributesJson: attributesJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryId,
            required String name,
            required String unit,
            required String attributesJson,
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            categoryId: categoryId,
            name: name,
            unit: unit,
            attributesJson: attributesJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProductsTable, Product>(table),
                    BaseReferences<_$AppDatabase, $ProductsTable, Product>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()>;
typedef $$LotsTableCreateCompanionBuilder = LotsCompanion Function({
  required String id,
  required String providerId,
  required String productId,
  required int quantityMilli,
  required String unit,
  required int unitPrice,
  Value<String?> qualityGrade,
  required DateTime availableFrom,
  required DateTime availableUntil,
  required String status,
  required int version,
  Value<String?> providerSummaryJson,
  Value<double?> distanceKm,
  required bool isMine,
  required String syncState,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LotsTableUpdateCompanionBuilder = LotsCompanion Function({
  Value<String> id,
  Value<String> providerId,
  Value<String> productId,
  Value<int> quantityMilli,
  Value<String> unit,
  Value<int> unitPrice,
  Value<String?> qualityGrade,
  Value<DateTime> availableFrom,
  Value<DateTime> availableUntil,
  Value<String> status,
  Value<int> version,
  Value<String?> providerSummaryJson,
  Value<double?> distanceKm,
  Value<bool> isMine,
  Value<String> syncState,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LotsTableFilterComposer extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantityMilli => $composableBuilder(
      column: $table.quantityMilli, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get availableFrom => $composableBuilder(
      column: $table.availableFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get availableUntil => $composableBuilder(
      column: $table.availableUntil,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerSummaryJson => $composableBuilder(
      column: $table.providerSummaryJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMine => $composableBuilder(
      column: $table.isMine, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LotsTableOrderingComposer extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
      column: $table.quantityMilli,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get availableFrom => $composableBuilder(
      column: $table.availableFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get availableUntil => $composableBuilder(
      column: $table.availableUntil,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerSummaryJson => $composableBuilder(
      column: $table.providerSummaryJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMine => $composableBuilder(
      column: $table.isMine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
      column: $table.quantityMilli, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get qualityGrade => $composableBuilder(
      column: $table.qualityGrade, builder: (column) => column);

  GeneratedColumn<DateTime> get availableFrom => $composableBuilder(
      column: $table.availableFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get availableUntil => $composableBuilder(
      column: $table.availableUntil, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get providerSummaryJson => $composableBuilder(
      column: $table.providerSummaryJson, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => column);

  GeneratedColumn<bool> get isMine =>
      $composableBuilder(column: $table.isMine, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LotsTable,
    Lot,
    $$LotsTableFilterComposer,
    $$LotsTableOrderingComposer,
    $$LotsTableAnnotationComposer,
    $$LotsTableCreateCompanionBuilder,
    $$LotsTableUpdateCompanionBuilder,
    (Lot, BaseReferences<_$AppDatabase, $LotsTable, Lot>),
    Lot,
    PrefetchHooks Function()> {
  $$LotsTableTableManager(_$AppDatabase db, $LotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<int> quantityMilli = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> unitPrice = const Value.absent(),
            Value<String?> qualityGrade = const Value.absent(),
            Value<DateTime> availableFrom = const Value.absent(),
            Value<DateTime> availableUntil = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String?> providerSummaryJson = const Value.absent(),
            Value<double?> distanceKm = const Value.absent(),
            Value<bool> isMine = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LotsCompanion(
            id: id,
            providerId: providerId,
            productId: productId,
            quantityMilli: quantityMilli,
            unit: unit,
            unitPrice: unitPrice,
            qualityGrade: qualityGrade,
            availableFrom: availableFrom,
            availableUntil: availableUntil,
            status: status,
            version: version,
            providerSummaryJson: providerSummaryJson,
            distanceKm: distanceKm,
            isMine: isMine,
            syncState: syncState,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String providerId,
            required String productId,
            required int quantityMilli,
            required String unit,
            required int unitPrice,
            Value<String?> qualityGrade = const Value.absent(),
            required DateTime availableFrom,
            required DateTime availableUntil,
            required String status,
            required int version,
            Value<String?> providerSummaryJson = const Value.absent(),
            Value<double?> distanceKm = const Value.absent(),
            required bool isMine,
            required String syncState,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LotsCompanion.insert(
            id: id,
            providerId: providerId,
            productId: productId,
            quantityMilli: quantityMilli,
            unit: unit,
            unitPrice: unitPrice,
            qualityGrade: qualityGrade,
            availableFrom: availableFrom,
            availableUntil: availableUntil,
            status: status,
            version: version,
            providerSummaryJson: providerSummaryJson,
            distanceKm: distanceKm,
            isMine: isMine,
            syncState: syncState,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LotsTable, Lot>(table),
                    BaseReferences<_$AppDatabase, $LotsTable, Lot>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LotsTable,
    Lot,
    $$LotsTableFilterComposer,
    $$LotsTableOrderingComposer,
    $$LotsTableAnnotationComposer,
    $$LotsTableCreateCompanionBuilder,
    $$LotsTableUpdateCompanionBuilder,
    (Lot, BaseReferences<_$AppDatabase, $LotsTable, Lot>),
    Lot,
    PrefetchHooks Function()>;
typedef $$OutboxOperationsTableCreateCompanionBuilder
    = OutboxOperationsCompanion Function({
  required String opId,
  Value<String?> ownerUserId,
  required String entity,
  required String entityId,
  required String type,
  required String payloadJson,
  Value<int?> baseVersion,
  required DateTime clientTs,
  required String status,
  required int attempts,
  required DateTime nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$OutboxOperationsTableUpdateCompanionBuilder
    = OutboxOperationsCompanion Function({
  Value<String> opId,
  Value<String?> ownerUserId,
  Value<String> entity,
  Value<String> entityId,
  Value<String> type,
  Value<String> payloadJson,
  Value<int?> baseVersion,
  Value<DateTime> clientTs,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$OutboxOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerUserId => $composableBuilder(
      column: $table.ownerUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get clientTs => $composableBuilder(
      column: $table.clientTs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$OutboxOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
      column: $table.ownerUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get clientTs => $composableBuilder(
      column: $table.clientTs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$OutboxOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOperationsTable> {
  $$OutboxOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
      column: $table.ownerUserId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get clientTs =>
      $composableBuilder(column: $table.clientTs, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxOperationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxOperationsTable,
    OutboxOperation,
    $$OutboxOperationsTableFilterComposer,
    $$OutboxOperationsTableOrderingComposer,
    $$OutboxOperationsTableAnnotationComposer,
    $$OutboxOperationsTableCreateCompanionBuilder,
    $$OutboxOperationsTableUpdateCompanionBuilder,
    (
      OutboxOperation,
      BaseReferences<_$AppDatabase, $OutboxOperationsTable, OutboxOperation>
    ),
    OutboxOperation,
    PrefetchHooks Function()> {
  $$OutboxOperationsTableTableManager(
      _$AppDatabase db, $OutboxOperationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> opId = const Value.absent(),
            Value<String?> ownerUserId = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int?> baseVersion = const Value.absent(),
            Value<DateTime> clientTs = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOperationsCompanion(
            opId: opId,
            ownerUserId: ownerUserId,
            entity: entity,
            entityId: entityId,
            type: type,
            payloadJson: payloadJson,
            baseVersion: baseVersion,
            clientTs: clientTs,
            status: status,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String opId,
            Value<String?> ownerUserId = const Value.absent(),
            required String entity,
            required String entityId,
            required String type,
            required String payloadJson,
            Value<int?> baseVersion = const Value.absent(),
            required DateTime clientTs,
            required String status,
            required int attempts,
            required DateTime nextAttemptAt,
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOperationsCompanion.insert(
            opId: opId,
            ownerUserId: ownerUserId,
            entity: entity,
            entityId: entityId,
            type: type,
            payloadJson: payloadJson,
            baseVersion: baseVersion,
            clientTs: clientTs,
            status: status,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$OutboxOperationsTable, OutboxOperation>(table),
                    BaseReferences<_$AppDatabase, $OutboxOperationsTable,
                        OutboxOperation>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxOperationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxOperationsTable,
    OutboxOperation,
    $$OutboxOperationsTableFilterComposer,
    $$OutboxOperationsTableOrderingComposer,
    $$OutboxOperationsTableAnnotationComposer,
    $$OutboxOperationsTableCreateCompanionBuilder,
    $$OutboxOperationsTableUpdateCompanionBuilder,
    (
      OutboxOperation,
      BaseReferences<_$AppDatabase, $OutboxOperationsTable, OutboxOperation>
    ),
    OutboxOperation,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
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

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncStateTable, SyncStateData>(table),
                    BaseReferences<_$AppDatabase, $SyncStateTable,
                        SyncStateData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;
typedef $$ConsentStateTableCreateCompanionBuilder = ConsentStateCompanion
    Function({
  required String version,
  required DateTime acceptedAt,
  Value<int> rowid,
});
typedef $$ConsentStateTableUpdateCompanionBuilder = ConsentStateCompanion
    Function({
  Value<String> version,
  Value<DateTime> acceptedAt,
  Value<int> rowid,
});

class $$ConsentStateTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentStateTable> {
  $$ConsentStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnFilters(column));
}

class $$ConsentStateTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentStateTable> {
  $$ConsentStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConsentStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentStateTable> {
  $$ConsentStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
      column: $table.acceptedAt, builder: (column) => column);
}

class $$ConsentStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConsentStateTable,
    ConsentStateData,
    $$ConsentStateTableFilterComposer,
    $$ConsentStateTableOrderingComposer,
    $$ConsentStateTableAnnotationComposer,
    $$ConsentStateTableCreateCompanionBuilder,
    $$ConsentStateTableUpdateCompanionBuilder,
    (
      ConsentStateData,
      BaseReferences<_$AppDatabase, $ConsentStateTable, ConsentStateData>
    ),
    ConsentStateData,
    PrefetchHooks Function()> {
  $$ConsentStateTableTableManager(_$AppDatabase db, $ConsentStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> version = const Value.absent(),
            Value<DateTime> acceptedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentStateCompanion(
            version: version,
            acceptedAt: acceptedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String version,
            required DateTime acceptedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentStateCompanion.insert(
            version: version,
            acceptedAt: acceptedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ConsentStateTable, ConsentStateData>(table),
                    BaseReferences<_$AppDatabase, $ConsentStateTable,
                        ConsentStateData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConsentStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConsentStateTable,
    ConsentStateData,
    $$ConsentStateTableFilterComposer,
    $$ConsentStateTableOrderingComposer,
    $$ConsentStateTableAnnotationComposer,
    $$ConsentStateTableCreateCompanionBuilder,
    $$ConsentStateTableUpdateCompanionBuilder,
    (
      ConsentStateData,
      BaseReferences<_$AppDatabase, $ConsentStateTable, ConsentStateData>
    ),
    ConsentStateData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ProviderProfilesTableTableManager get providerProfiles =>
      $$ProviderProfilesTableTableManager(_db, _db.providerProfiles);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$LotsTableTableManager get lots => $$LotsTableTableManager(_db, _db.lots);
  $$OutboxOperationsTableTableManager get outboxOperations =>
      $$OutboxOperationsTableTableManager(_db, _db.outboxOperations);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$ConsentStateTableTableManager get consentState =>
      $$ConsentStateTableTableManager(_db, _db.consentState);
}
