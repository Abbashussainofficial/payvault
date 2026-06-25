// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$AppSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  AppSettingsDaoManager get managers => AppSettingsDaoManager(this);
}

class AppSettingsDaoManager {
  final _$AppSettingsDaoMixin _db;
  AppSettingsDaoManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
}

mixin _$EmployeesDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  EmployeesDaoManager get managers => EmployeesDaoManager(this);
}

class EmployeesDaoManager {
  final _$EmployeesDaoMixin _db;
  EmployeesDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
}

mixin _$SalaryComponentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $SalaryComponentsTable get salaryComponents =>
      attachedDatabase.salaryComponents;
  SalaryComponentsDaoManager get managers => SalaryComponentsDaoManager(this);
}

class SalaryComponentsDaoManager {
  final _$SalaryComponentsDaoMixin _db;
  SalaryComponentsDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$SalaryComponentsTableTableManager get salaryComponents =>
      $$SalaryComponentsTableTableManager(
        _db.attachedDatabase,
        _db.salaryComponents,
      );
}

mixin _$PayrollRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $PayrollRecordsTable get payrollRecords => attachedDatabase.payrollRecords;
  PayrollRecordsDaoManager get managers => PayrollRecordsDaoManager(this);
}

class PayrollRecordsDaoManager {
  final _$PayrollRecordsDaoMixin _db;
  PayrollRecordsDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PayrollRecordsTableTableManager get payrollRecords =>
      $$PayrollRecordsTableTableManager(
        _db.attachedDatabase,
        _db.payrollRecords,
      );
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _securityQuestionMeta = const VerificationMeta(
    'securityQuestion',
  );
  @override
  late final GeneratedColumn<String> securityQuestion = GeneratedColumn<String>(
    'security_question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _securityAnswerHashMeta =
      const VerificationMeta('securityAnswerHash');
  @override
  late final GeneratedColumn<String> securityAnswerHash =
      GeneratedColumn<String>(
        'security_answer_hash',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _backupReminderDaysMeta =
      const VerificationMeta('backupReminderDays');
  @override
  late final GeneratedColumn<int> backupReminderDays = GeneratedColumn<int>(
    'backup_reminder_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _lastBackupDateMeta = const VerificationMeta(
    'lastBackupDate',
  );
  @override
  late final GeneratedColumn<String> lastBackupDate = GeneratedColumn<String>(
    'last_backup_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    passwordHash,
    securityQuestion,
    securityAnswerHash,
    themeMode,
    backupReminderDays,
    lastBackupDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('security_question')) {
      context.handle(
        _securityQuestionMeta,
        securityQuestion.isAcceptableOrUnknown(
          data['security_question']!,
          _securityQuestionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_securityQuestionMeta);
    }
    if (data.containsKey('security_answer_hash')) {
      context.handle(
        _securityAnswerHashMeta,
        securityAnswerHash.isAcceptableOrUnknown(
          data['security_answer_hash']!,
          _securityAnswerHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_securityAnswerHashMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('backup_reminder_days')) {
      context.handle(
        _backupReminderDaysMeta,
        backupReminderDays.isAcceptableOrUnknown(
          data['backup_reminder_days']!,
          _backupReminderDaysMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_date')) {
      context.handle(
        _lastBackupDateMeta,
        lastBackupDate.isAcceptableOrUnknown(
          data['last_backup_date']!,
          _lastBackupDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      securityQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_question'],
      )!,
      securityAnswerHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_answer_hash'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      backupReminderDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}backup_reminder_days'],
      )!,
      lastBackupDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_backup_date'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String passwordHash;
  final String securityQuestion;
  final String securityAnswerHash;
  final String themeMode;
  final int backupReminderDays;
  final String? lastBackupDate;
  const AppSetting({
    required this.id,
    required this.passwordHash,
    required this.securityQuestion,
    required this.securityAnswerHash,
    required this.themeMode,
    required this.backupReminderDays,
    this.lastBackupDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['password_hash'] = Variable<String>(passwordHash);
    map['security_question'] = Variable<String>(securityQuestion);
    map['security_answer_hash'] = Variable<String>(securityAnswerHash);
    map['theme_mode'] = Variable<String>(themeMode);
    map['backup_reminder_days'] = Variable<int>(backupReminderDays);
    if (!nullToAbsent || lastBackupDate != null) {
      map['last_backup_date'] = Variable<String>(lastBackupDate);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      passwordHash: Value(passwordHash),
      securityQuestion: Value(securityQuestion),
      securityAnswerHash: Value(securityAnswerHash),
      themeMode: Value(themeMode),
      backupReminderDays: Value(backupReminderDays),
      lastBackupDate: lastBackupDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupDate),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      securityQuestion: serializer.fromJson<String>(json['securityQuestion']),
      securityAnswerHash: serializer.fromJson<String>(
        json['securityAnswerHash'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      backupReminderDays: serializer.fromJson<int>(json['backupReminderDays']),
      lastBackupDate: serializer.fromJson<String?>(json['lastBackupDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'securityQuestion': serializer.toJson<String>(securityQuestion),
      'securityAnswerHash': serializer.toJson<String>(securityAnswerHash),
      'themeMode': serializer.toJson<String>(themeMode),
      'backupReminderDays': serializer.toJson<int>(backupReminderDays),
      'lastBackupDate': serializer.toJson<String?>(lastBackupDate),
    };
  }

  AppSetting copyWith({
    int? id,
    String? passwordHash,
    String? securityQuestion,
    String? securityAnswerHash,
    String? themeMode,
    int? backupReminderDays,
    Value<String?> lastBackupDate = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    passwordHash: passwordHash ?? this.passwordHash,
    securityQuestion: securityQuestion ?? this.securityQuestion,
    securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
    themeMode: themeMode ?? this.themeMode,
    backupReminderDays: backupReminderDays ?? this.backupReminderDays,
    lastBackupDate: lastBackupDate.present
        ? lastBackupDate.value
        : this.lastBackupDate,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      securityQuestion: data.securityQuestion.present
          ? data.securityQuestion.value
          : this.securityQuestion,
      securityAnswerHash: data.securityAnswerHash.present
          ? data.securityAnswerHash.value
          : this.securityAnswerHash,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      backupReminderDays: data.backupReminderDays.present
          ? data.backupReminderDays.value
          : this.backupReminderDays,
      lastBackupDate: data.lastBackupDate.present
          ? data.lastBackupDate.value
          : this.lastBackupDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('securityQuestion: $securityQuestion, ')
          ..write('securityAnswerHash: $securityAnswerHash, ')
          ..write('themeMode: $themeMode, ')
          ..write('backupReminderDays: $backupReminderDays, ')
          ..write('lastBackupDate: $lastBackupDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    passwordHash,
    securityQuestion,
    securityAnswerHash,
    themeMode,
    backupReminderDays,
    lastBackupDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.passwordHash == this.passwordHash &&
          other.securityQuestion == this.securityQuestion &&
          other.securityAnswerHash == this.securityAnswerHash &&
          other.themeMode == this.themeMode &&
          other.backupReminderDays == this.backupReminderDays &&
          other.lastBackupDate == this.lastBackupDate);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> passwordHash;
  final Value<String> securityQuestion;
  final Value<String> securityAnswerHash;
  final Value<String> themeMode;
  final Value<int> backupReminderDays;
  final Value<String?> lastBackupDate;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.securityQuestion = const Value.absent(),
    this.securityAnswerHash = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.backupReminderDays = const Value.absent(),
    this.lastBackupDate = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String passwordHash,
    required String securityQuestion,
    required String securityAnswerHash,
    this.themeMode = const Value.absent(),
    this.backupReminderDays = const Value.absent(),
    this.lastBackupDate = const Value.absent(),
  }) : passwordHash = Value(passwordHash),
       securityQuestion = Value(securityQuestion),
       securityAnswerHash = Value(securityAnswerHash);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? passwordHash,
    Expression<String>? securityQuestion,
    Expression<String>? securityAnswerHash,
    Expression<String>? themeMode,
    Expression<int>? backupReminderDays,
    Expression<String>? lastBackupDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (securityQuestion != null) 'security_question': securityQuestion,
      if (securityAnswerHash != null)
        'security_answer_hash': securityAnswerHash,
      if (themeMode != null) 'theme_mode': themeMode,
      if (backupReminderDays != null)
        'backup_reminder_days': backupReminderDays,
      if (lastBackupDate != null) 'last_backup_date': lastBackupDate,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? passwordHash,
    Value<String>? securityQuestion,
    Value<String>? securityAnswerHash,
    Value<String>? themeMode,
    Value<int>? backupReminderDays,
    Value<String?>? lastBackupDate,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      passwordHash: passwordHash ?? this.passwordHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      themeMode: themeMode ?? this.themeMode,
      backupReminderDays: backupReminderDays ?? this.backupReminderDays,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (securityQuestion.present) {
      map['security_question'] = Variable<String>(securityQuestion.value);
    }
    if (securityAnswerHash.present) {
      map['security_answer_hash'] = Variable<String>(securityAnswerHash.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (backupReminderDays.present) {
      map['backup_reminder_days'] = Variable<int>(backupReminderDays.value);
    }
    if (lastBackupDate.present) {
      map['last_backup_date'] = Variable<String>(lastBackupDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('securityQuestion: $securityQuestion, ')
          ..write('securityAnswerHash: $securityAnswerHash, ')
          ..write('themeMode: $themeMode, ')
          ..write('backupReminderDays: $backupReminderDays, ')
          ..write('lastBackupDate: $lastBackupDate')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, Employee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _designationMeta = const VerificationMeta(
    'designation',
  );
  @override
  late final GeneratedColumn<String> designation = GeneratedColumn<String>(
    'designation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpsGradeMeta = const VerificationMeta(
    'bpsGrade',
  );
  @override
  late final GeneratedColumn<String> bpsGrade = GeneratedColumn<String>(
    'bps_grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactNumberMeta = const VerificationMeta(
    'contactNumber',
  );
  @override
  late final GeneratedColumn<String> contactNumber = GeneratedColumn<String>(
    'contact_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cnicMeta = const VerificationMeta('cnic');
  @override
  late final GeneratedColumn<String> cnic = GeneratedColumn<String>(
    'cnic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _joiningDateMeta = const VerificationMeta(
    'joiningDate',
  );
  @override
  late final GeneratedColumn<String> joiningDate = GeneratedColumn<String>(
    'joining_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leavingDateMeta = const VerificationMeta(
    'leavingDate',
  );
  @override
  late final GeneratedColumn<String> leavingDate = GeneratedColumn<String>(
    'leaving_date',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseSalaryMeta = const VerificationMeta(
    'baseSalary',
  );
  @override
  late final GeneratedColumn<double> baseSalary = GeneratedColumn<double>(
    'base_salary',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    fullName,
    designation,
    department,
    bpsGrade,
    contactNumber,
    cnic,
    joiningDate,
    leavingDate,
    status,
    category,
    baseSalary,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(
    Insertable<Employee> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('designation')) {
      context.handle(
        _designationMeta,
        designation.isAcceptableOrUnknown(
          data['designation']!,
          _designationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_designationMeta);
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    } else if (isInserting) {
      context.missing(_departmentMeta);
    }
    if (data.containsKey('bps_grade')) {
      context.handle(
        _bpsGradeMeta,
        bpsGrade.isAcceptableOrUnknown(data['bps_grade']!, _bpsGradeMeta),
      );
    }
    if (data.containsKey('contact_number')) {
      context.handle(
        _contactNumberMeta,
        contactNumber.isAcceptableOrUnknown(
          data['contact_number']!,
          _contactNumberMeta,
        ),
      );
    }
    if (data.containsKey('cnic')) {
      context.handle(
        _cnicMeta,
        cnic.isAcceptableOrUnknown(data['cnic']!, _cnicMeta),
      );
    }
    if (data.containsKey('joining_date')) {
      context.handle(
        _joiningDateMeta,
        joiningDate.isAcceptableOrUnknown(
          data['joining_date']!,
          _joiningDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_joiningDateMeta);
    }
    if (data.containsKey('leaving_date')) {
      context.handle(
        _leavingDateMeta,
        leavingDate.isAcceptableOrUnknown(
          data['leaving_date']!,
          _leavingDateMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('base_salary')) {
      context.handle(
        _baseSalaryMeta,
        baseSalary.isAcceptableOrUnknown(data['base_salary']!, _baseSalaryMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {employeeId, category},
  ];
  @override
  Employee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employee(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      designation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}designation'],
      )!,
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      )!,
      bpsGrade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bps_grade'],
      ),
      contactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_number'],
      ),
      cnic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnic'],
      ),
      joiningDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joining_date'],
      )!,
      leavingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}leaving_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      baseSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_salary'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class Employee extends DataClass implements Insertable<Employee> {
  final int id;
  final String employeeId;
  final String fullName;
  final String designation;
  final String department;
  final String? bpsGrade;
  final String? contactNumber;
  final String? cnic;
  final String joiningDate;
  final String? leavingDate;
  final String status;
  final String category;
  final double baseSalary;
  final String createdAt;
  const Employee({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.designation,
    required this.department,
    this.bpsGrade,
    this.contactNumber,
    this.cnic,
    required this.joiningDate,
    this.leavingDate,
    required this.status,
    required this.category,
    required this.baseSalary,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['full_name'] = Variable<String>(fullName);
    map['designation'] = Variable<String>(designation);
    map['department'] = Variable<String>(department);
    if (!nullToAbsent || bpsGrade != null) {
      map['bps_grade'] = Variable<String>(bpsGrade);
    }
    if (!nullToAbsent || contactNumber != null) {
      map['contact_number'] = Variable<String>(contactNumber);
    }
    if (!nullToAbsent || cnic != null) {
      map['cnic'] = Variable<String>(cnic);
    }
    map['joining_date'] = Variable<String>(joiningDate);
    if (!nullToAbsent || leavingDate != null) {
      map['leaving_date'] = Variable<String>(leavingDate);
    }
    map['status'] = Variable<String>(status);
    map['category'] = Variable<String>(category);
    map['base_salary'] = Variable<double>(baseSalary);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      fullName: Value(fullName),
      designation: Value(designation),
      department: Value(department),
      bpsGrade: bpsGrade == null && nullToAbsent
          ? const Value.absent()
          : Value(bpsGrade),
      contactNumber: contactNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(contactNumber),
      cnic: cnic == null && nullToAbsent ? const Value.absent() : Value(cnic),
      joiningDate: Value(joiningDate),
      leavingDate: leavingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(leavingDate),
      status: Value(status),
      category: Value(category),
      baseSalary: Value(baseSalary),
      createdAt: Value(createdAt),
    );
  }

  factory Employee.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employee(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      designation: serializer.fromJson<String>(json['designation']),
      department: serializer.fromJson<String>(json['department']),
      bpsGrade: serializer.fromJson<String?>(json['bpsGrade']),
      contactNumber: serializer.fromJson<String?>(json['contactNumber']),
      cnic: serializer.fromJson<String?>(json['cnic']),
      joiningDate: serializer.fromJson<String>(json['joiningDate']),
      leavingDate: serializer.fromJson<String?>(json['leavingDate']),
      status: serializer.fromJson<String>(json['status']),
      category: serializer.fromJson<String>(json['category']),
      baseSalary: serializer.fromJson<double>(json['baseSalary']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'fullName': serializer.toJson<String>(fullName),
      'designation': serializer.toJson<String>(designation),
      'department': serializer.toJson<String>(department),
      'bpsGrade': serializer.toJson<String?>(bpsGrade),
      'contactNumber': serializer.toJson<String?>(contactNumber),
      'cnic': serializer.toJson<String?>(cnic),
      'joiningDate': serializer.toJson<String>(joiningDate),
      'leavingDate': serializer.toJson<String?>(leavingDate),
      'status': serializer.toJson<String>(status),
      'category': serializer.toJson<String>(category),
      'baseSalary': serializer.toJson<double>(baseSalary),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Employee copyWith({
    int? id,
    String? employeeId,
    String? fullName,
    String? designation,
    String? department,
    Value<String?> bpsGrade = const Value.absent(),
    Value<String?> contactNumber = const Value.absent(),
    Value<String?> cnic = const Value.absent(),
    String? joiningDate,
    Value<String?> leavingDate = const Value.absent(),
    String? status,
    String? category,
    double? baseSalary,
    String? createdAt,
  }) => Employee(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    fullName: fullName ?? this.fullName,
    designation: designation ?? this.designation,
    department: department ?? this.department,
    bpsGrade: bpsGrade.present ? bpsGrade.value : this.bpsGrade,
    contactNumber: contactNumber.present
        ? contactNumber.value
        : this.contactNumber,
    cnic: cnic.present ? cnic.value : this.cnic,
    joiningDate: joiningDate ?? this.joiningDate,
    leavingDate: leavingDate.present ? leavingDate.value : this.leavingDate,
    status: status ?? this.status,
    category: category ?? this.category,
    baseSalary: baseSalary ?? this.baseSalary,
    createdAt: createdAt ?? this.createdAt,
  );
  Employee copyWithCompanion(EmployeesCompanion data) {
    return Employee(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      designation: data.designation.present
          ? data.designation.value
          : this.designation,
      department: data.department.present
          ? data.department.value
          : this.department,
      bpsGrade: data.bpsGrade.present ? data.bpsGrade.value : this.bpsGrade,
      contactNumber: data.contactNumber.present
          ? data.contactNumber.value
          : this.contactNumber,
      cnic: data.cnic.present ? data.cnic.value : this.cnic,
      joiningDate: data.joiningDate.present
          ? data.joiningDate.value
          : this.joiningDate,
      leavingDate: data.leavingDate.present
          ? data.leavingDate.value
          : this.leavingDate,
      status: data.status.present ? data.status.value : this.status,
      category: data.category.present ? data.category.value : this.category,
      baseSalary: data.baseSalary.present
          ? data.baseSalary.value
          : this.baseSalary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employee(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('designation: $designation, ')
          ..write('department: $department, ')
          ..write('bpsGrade: $bpsGrade, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('cnic: $cnic, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('leavingDate: $leavingDate, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    fullName,
    designation,
    department,
    bpsGrade,
    contactNumber,
    cnic,
    joiningDate,
    leavingDate,
    status,
    category,
    baseSalary,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.fullName == this.fullName &&
          other.designation == this.designation &&
          other.department == this.department &&
          other.bpsGrade == this.bpsGrade &&
          other.contactNumber == this.contactNumber &&
          other.cnic == this.cnic &&
          other.joiningDate == this.joiningDate &&
          other.leavingDate == this.leavingDate &&
          other.status == this.status &&
          other.category == this.category &&
          other.baseSalary == this.baseSalary &&
          other.createdAt == this.createdAt);
}

class EmployeesCompanion extends UpdateCompanion<Employee> {
  final Value<int> id;
  final Value<String> employeeId;
  final Value<String> fullName;
  final Value<String> designation;
  final Value<String> department;
  final Value<String?> bpsGrade;
  final Value<String?> contactNumber;
  final Value<String?> cnic;
  final Value<String> joiningDate;
  final Value<String?> leavingDate;
  final Value<String> status;
  final Value<String> category;
  final Value<double> baseSalary;
  final Value<String> createdAt;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.designation = const Value.absent(),
    this.department = const Value.absent(),
    this.bpsGrade = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.cnic = const Value.absent(),
    this.joiningDate = const Value.absent(),
    this.leavingDate = const Value.absent(),
    this.status = const Value.absent(),
    this.category = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmployeesCompanion.insert({
    this.id = const Value.absent(),
    required String employeeId,
    required String fullName,
    required String designation,
    required String department,
    this.bpsGrade = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.cnic = const Value.absent(),
    required String joiningDate,
    this.leavingDate = const Value.absent(),
    required String status,
    required String category,
    this.baseSalary = const Value.absent(),
    required String createdAt,
  }) : employeeId = Value(employeeId),
       fullName = Value(fullName),
       designation = Value(designation),
       department = Value(department),
       joiningDate = Value(joiningDate),
       status = Value(status),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<Employee> custom({
    Expression<int>? id,
    Expression<String>? employeeId,
    Expression<String>? fullName,
    Expression<String>? designation,
    Expression<String>? department,
    Expression<String>? bpsGrade,
    Expression<String>? contactNumber,
    Expression<String>? cnic,
    Expression<String>? joiningDate,
    Expression<String>? leavingDate,
    Expression<String>? status,
    Expression<String>? category,
    Expression<double>? baseSalary,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (fullName != null) 'full_name': fullName,
      if (designation != null) 'designation': designation,
      if (department != null) 'department': department,
      if (bpsGrade != null) 'bps_grade': bpsGrade,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (cnic != null) 'cnic': cnic,
      if (joiningDate != null) 'joining_date': joiningDate,
      if (leavingDate != null) 'leaving_date': leavingDate,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmployeesCompanion copyWith({
    Value<int>? id,
    Value<String>? employeeId,
    Value<String>? fullName,
    Value<String>? designation,
    Value<String>? department,
    Value<String?>? bpsGrade,
    Value<String?>? contactNumber,
    Value<String?>? cnic,
    Value<String>? joiningDate,
    Value<String?>? leavingDate,
    Value<String>? status,
    Value<String>? category,
    Value<double>? baseSalary,
    Value<String>? createdAt,
  }) {
    return EmployeesCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      bpsGrade: bpsGrade ?? this.bpsGrade,
      contactNumber: contactNumber ?? this.contactNumber,
      cnic: cnic ?? this.cnic,
      joiningDate: joiningDate ?? this.joiningDate,
      leavingDate: leavingDate ?? this.leavingDate,
      status: status ?? this.status,
      category: category ?? this.category,
      baseSalary: baseSalary ?? this.baseSalary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (designation.present) {
      map['designation'] = Variable<String>(designation.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (bpsGrade.present) {
      map['bps_grade'] = Variable<String>(bpsGrade.value);
    }
    if (contactNumber.present) {
      map['contact_number'] = Variable<String>(contactNumber.value);
    }
    if (cnic.present) {
      map['cnic'] = Variable<String>(cnic.value);
    }
    if (joiningDate.present) {
      map['joining_date'] = Variable<String>(joiningDate.value);
    }
    if (leavingDate.present) {
      map['leaving_date'] = Variable<String>(leavingDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (baseSalary.present) {
      map['base_salary'] = Variable<double>(baseSalary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('designation: $designation, ')
          ..write('department: $department, ')
          ..write('bpsGrade: $bpsGrade, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('cnic: $cnic, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('leavingDate: $leavingDate, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SalaryComponentsTable extends SalaryComponents
    with TableInfo<$SalaryComponentsTable, SalaryComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalaryComponentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employees (id)',
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
  static const VerificationMeta _componentTypeMeta = const VerificationMeta(
    'componentType',
  );
  @override
  late final GeneratedColumn<String> componentType = GeneratedColumn<String>(
    'component_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classificationCodeMeta =
      const VerificationMeta('classificationCode');
  @override
  late final GeneratedColumn<String> classificationCode =
      GeneratedColumn<String>(
        'classification_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _freezeModeMeta = const VerificationMeta(
    'freezeMode',
  );
  @override
  late final GeneratedColumn<String> freezeMode = GeneratedColumn<String>(
    'freeze_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_frozen'),
  );
  static const VerificationMeta _frozenAmountMeta = const VerificationMeta(
    'frozenAmount',
  );
  @override
  late final GeneratedColumn<double> frozenAmount = GeneratedColumn<double>(
    'frozen_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frozenBaseMeta = const VerificationMeta(
    'frozenBase',
  );
  @override
  late final GeneratedColumn<double> frozenBase = GeneratedColumn<double>(
    'frozen_base',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freezeDateMeta = const VerificationMeta(
    'freezeDate',
  );
  @override
  late final GeneratedColumn<String> freezeDate = GeneratedColumn<String>(
    'freeze_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _allowanceSectionMeta = const VerificationMeta(
    'allowanceSection',
  );
  @override
  late final GeneratedColumn<String> allowanceSection = GeneratedColumn<String>(
    'allowance_section',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    name,
    componentType,
    valueType,
    value,
    classificationCode,
    freezeMode,
    frozenAmount,
    frozenBase,
    freezeDate,
    isActive,
    sortOrder,
    allowanceSection,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'salary_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalaryComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('component_type')) {
      context.handle(
        _componentTypeMeta,
        componentType.isAcceptableOrUnknown(
          data['component_type']!,
          _componentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentTypeMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('classification_code')) {
      context.handle(
        _classificationCodeMeta,
        classificationCode.isAcceptableOrUnknown(
          data['classification_code']!,
          _classificationCodeMeta,
        ),
      );
    }
    if (data.containsKey('freeze_mode')) {
      context.handle(
        _freezeModeMeta,
        freezeMode.isAcceptableOrUnknown(data['freeze_mode']!, _freezeModeMeta),
      );
    }
    if (data.containsKey('frozen_amount')) {
      context.handle(
        _frozenAmountMeta,
        frozenAmount.isAcceptableOrUnknown(
          data['frozen_amount']!,
          _frozenAmountMeta,
        ),
      );
    }
    if (data.containsKey('frozen_base')) {
      context.handle(
        _frozenBaseMeta,
        frozenBase.isAcceptableOrUnknown(data['frozen_base']!, _frozenBaseMeta),
      );
    }
    if (data.containsKey('freeze_date')) {
      context.handle(
        _freezeDateMeta,
        freezeDate.isAcceptableOrUnknown(data['freeze_date']!, _freezeDateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('allowance_section')) {
      context.handle(
        _allowanceSectionMeta,
        allowanceSection.isAcceptableOrUnknown(
          data['allowance_section']!,
          _allowanceSectionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalaryComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalaryComponent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employee_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      componentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_type'],
      )!,
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      classificationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classification_code'],
      ),
      freezeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freeze_mode'],
      )!,
      frozenAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frozen_amount'],
      ),
      frozenBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frozen_base'],
      ),
      freezeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freeze_date'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      allowanceSection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allowance_section'],
      ),
    );
  }

  @override
  $SalaryComponentsTable createAlias(String alias) {
    return $SalaryComponentsTable(attachedDatabase, alias);
  }
}

class SalaryComponent extends DataClass implements Insertable<SalaryComponent> {
  final int id;
  final int employeeId;
  final String name;
  final String componentType;
  final String valueType;
  final double value;
  final String? classificationCode;
  final String freezeMode;
  final double? frozenAmount;
  final double? frozenBase;
  final String? freezeDate;
  final bool isActive;
  final int sortOrder;
  final String? allowanceSection;
  const SalaryComponent({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.componentType,
    required this.valueType,
    required this.value,
    this.classificationCode,
    required this.freezeMode,
    this.frozenAmount,
    this.frozenBase,
    this.freezeDate,
    required this.isActive,
    required this.sortOrder,
    this.allowanceSection,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['name'] = Variable<String>(name);
    map['component_type'] = Variable<String>(componentType);
    map['value_type'] = Variable<String>(valueType);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || classificationCode != null) {
      map['classification_code'] = Variable<String>(classificationCode);
    }
    map['freeze_mode'] = Variable<String>(freezeMode);
    if (!nullToAbsent || frozenAmount != null) {
      map['frozen_amount'] = Variable<double>(frozenAmount);
    }
    if (!nullToAbsent || frozenBase != null) {
      map['frozen_base'] = Variable<double>(frozenBase);
    }
    if (!nullToAbsent || freezeDate != null) {
      map['freeze_date'] = Variable<String>(freezeDate);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || allowanceSection != null) {
      map['allowance_section'] = Variable<String>(allowanceSection);
    }
    return map;
  }

  SalaryComponentsCompanion toCompanion(bool nullToAbsent) {
    return SalaryComponentsCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      name: Value(name),
      componentType: Value(componentType),
      valueType: Value(valueType),
      value: Value(value),
      classificationCode: classificationCode == null && nullToAbsent
          ? const Value.absent()
          : Value(classificationCode),
      freezeMode: Value(freezeMode),
      frozenAmount: frozenAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(frozenAmount),
      frozenBase: frozenBase == null && nullToAbsent
          ? const Value.absent()
          : Value(frozenBase),
      freezeDate: freezeDate == null && nullToAbsent
          ? const Value.absent()
          : Value(freezeDate),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      allowanceSection: allowanceSection == null && nullToAbsent
          ? const Value.absent()
          : Value(allowanceSection),
    );
  }

  factory SalaryComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalaryComponent(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      name: serializer.fromJson<String>(json['name']),
      componentType: serializer.fromJson<String>(json['componentType']),
      valueType: serializer.fromJson<String>(json['valueType']),
      value: serializer.fromJson<double>(json['value']),
      classificationCode: serializer.fromJson<String?>(
        json['classificationCode'],
      ),
      freezeMode: serializer.fromJson<String>(json['freezeMode']),
      frozenAmount: serializer.fromJson<double?>(json['frozenAmount']),
      frozenBase: serializer.fromJson<double?>(json['frozenBase']),
      freezeDate: serializer.fromJson<String?>(json['freezeDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      allowanceSection: serializer.fromJson<String?>(json['allowanceSection']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'name': serializer.toJson<String>(name),
      'componentType': serializer.toJson<String>(componentType),
      'valueType': serializer.toJson<String>(valueType),
      'value': serializer.toJson<double>(value),
      'classificationCode': serializer.toJson<String?>(classificationCode),
      'freezeMode': serializer.toJson<String>(freezeMode),
      'frozenAmount': serializer.toJson<double?>(frozenAmount),
      'frozenBase': serializer.toJson<double?>(frozenBase),
      'freezeDate': serializer.toJson<String?>(freezeDate),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'allowanceSection': serializer.toJson<String?>(allowanceSection),
    };
  }

  SalaryComponent copyWith({
    int? id,
    int? employeeId,
    String? name,
    String? componentType,
    String? valueType,
    double? value,
    Value<String?> classificationCode = const Value.absent(),
    String? freezeMode,
    Value<double?> frozenAmount = const Value.absent(),
    Value<double?> frozenBase = const Value.absent(),
    Value<String?> freezeDate = const Value.absent(),
    bool? isActive,
    int? sortOrder,
    Value<String?> allowanceSection = const Value.absent(),
  }) => SalaryComponent(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    name: name ?? this.name,
    componentType: componentType ?? this.componentType,
    valueType: valueType ?? this.valueType,
    value: value ?? this.value,
    classificationCode: classificationCode.present
        ? classificationCode.value
        : this.classificationCode,
    freezeMode: freezeMode ?? this.freezeMode,
    frozenAmount: frozenAmount.present ? frozenAmount.value : this.frozenAmount,
    frozenBase: frozenBase.present ? frozenBase.value : this.frozenBase,
    freezeDate: freezeDate.present ? freezeDate.value : this.freezeDate,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    allowanceSection: allowanceSection.present
        ? allowanceSection.value
        : this.allowanceSection,
  );
  SalaryComponent copyWithCompanion(SalaryComponentsCompanion data) {
    return SalaryComponent(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      name: data.name.present ? data.name.value : this.name,
      componentType: data.componentType.present
          ? data.componentType.value
          : this.componentType,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      value: data.value.present ? data.value.value : this.value,
      classificationCode: data.classificationCode.present
          ? data.classificationCode.value
          : this.classificationCode,
      freezeMode: data.freezeMode.present
          ? data.freezeMode.value
          : this.freezeMode,
      frozenAmount: data.frozenAmount.present
          ? data.frozenAmount.value
          : this.frozenAmount,
      frozenBase: data.frozenBase.present
          ? data.frozenBase.value
          : this.frozenBase,
      freezeDate: data.freezeDate.present
          ? data.freezeDate.value
          : this.freezeDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      allowanceSection: data.allowanceSection.present
          ? data.allowanceSection.value
          : this.allowanceSection,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalaryComponent(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('valueType: $valueType, ')
          ..write('value: $value, ')
          ..write('classificationCode: $classificationCode, ')
          ..write('freezeMode: $freezeMode, ')
          ..write('frozenAmount: $frozenAmount, ')
          ..write('frozenBase: $frozenBase, ')
          ..write('freezeDate: $freezeDate, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('allowanceSection: $allowanceSection')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    name,
    componentType,
    valueType,
    value,
    classificationCode,
    freezeMode,
    frozenAmount,
    frozenBase,
    freezeDate,
    isActive,
    sortOrder,
    allowanceSection,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalaryComponent &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.name == this.name &&
          other.componentType == this.componentType &&
          other.valueType == this.valueType &&
          other.value == this.value &&
          other.classificationCode == this.classificationCode &&
          other.freezeMode == this.freezeMode &&
          other.frozenAmount == this.frozenAmount &&
          other.frozenBase == this.frozenBase &&
          other.freezeDate == this.freezeDate &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.allowanceSection == this.allowanceSection);
}

class SalaryComponentsCompanion extends UpdateCompanion<SalaryComponent> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<String> name;
  final Value<String> componentType;
  final Value<String> valueType;
  final Value<double> value;
  final Value<String?> classificationCode;
  final Value<String> freezeMode;
  final Value<double?> frozenAmount;
  final Value<double?> frozenBase;
  final Value<String?> freezeDate;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<String?> allowanceSection;
  const SalaryComponentsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.name = const Value.absent(),
    this.componentType = const Value.absent(),
    this.valueType = const Value.absent(),
    this.value = const Value.absent(),
    this.classificationCode = const Value.absent(),
    this.freezeMode = const Value.absent(),
    this.frozenAmount = const Value.absent(),
    this.frozenBase = const Value.absent(),
    this.freezeDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.allowanceSection = const Value.absent(),
  });
  SalaryComponentsCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required String name,
    required String componentType,
    required String valueType,
    required double value,
    this.classificationCode = const Value.absent(),
    this.freezeMode = const Value.absent(),
    this.frozenAmount = const Value.absent(),
    this.frozenBase = const Value.absent(),
    this.freezeDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.allowanceSection = const Value.absent(),
  }) : employeeId = Value(employeeId),
       name = Value(name),
       componentType = Value(componentType),
       valueType = Value(valueType),
       value = Value(value);
  static Insertable<SalaryComponent> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<String>? name,
    Expression<String>? componentType,
    Expression<String>? valueType,
    Expression<double>? value,
    Expression<String>? classificationCode,
    Expression<String>? freezeMode,
    Expression<double>? frozenAmount,
    Expression<double>? frozenBase,
    Expression<String>? freezeDate,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<String>? allowanceSection,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (name != null) 'name': name,
      if (componentType != null) 'component_type': componentType,
      if (valueType != null) 'value_type': valueType,
      if (value != null) 'value': value,
      if (classificationCode != null) 'classification_code': classificationCode,
      if (freezeMode != null) 'freeze_mode': freezeMode,
      if (frozenAmount != null) 'frozen_amount': frozenAmount,
      if (frozenBase != null) 'frozen_base': frozenBase,
      if (freezeDate != null) 'freeze_date': freezeDate,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (allowanceSection != null) 'allowance_section': allowanceSection,
    });
  }

  SalaryComponentsCompanion copyWith({
    Value<int>? id,
    Value<int>? employeeId,
    Value<String>? name,
    Value<String>? componentType,
    Value<String>? valueType,
    Value<double>? value,
    Value<String?>? classificationCode,
    Value<String>? freezeMode,
    Value<double?>? frozenAmount,
    Value<double?>? frozenBase,
    Value<String?>? freezeDate,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<String?>? allowanceSection,
  }) {
    return SalaryComponentsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      componentType: componentType ?? this.componentType,
      valueType: valueType ?? this.valueType,
      value: value ?? this.value,
      classificationCode: classificationCode ?? this.classificationCode,
      freezeMode: freezeMode ?? this.freezeMode,
      frozenAmount: frozenAmount ?? this.frozenAmount,
      frozenBase: frozenBase ?? this.frozenBase,
      freezeDate: freezeDate ?? this.freezeDate,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      allowanceSection: allowanceSection ?? this.allowanceSection,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (componentType.present) {
      map['component_type'] = Variable<String>(componentType.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (classificationCode.present) {
      map['classification_code'] = Variable<String>(classificationCode.value);
    }
    if (freezeMode.present) {
      map['freeze_mode'] = Variable<String>(freezeMode.value);
    }
    if (frozenAmount.present) {
      map['frozen_amount'] = Variable<double>(frozenAmount.value);
    }
    if (frozenBase.present) {
      map['frozen_base'] = Variable<double>(frozenBase.value);
    }
    if (freezeDate.present) {
      map['freeze_date'] = Variable<String>(freezeDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (allowanceSection.present) {
      map['allowance_section'] = Variable<String>(allowanceSection.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalaryComponentsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('name: $name, ')
          ..write('componentType: $componentType, ')
          ..write('valueType: $valueType, ')
          ..write('value: $value, ')
          ..write('classificationCode: $classificationCode, ')
          ..write('freezeMode: $freezeMode, ')
          ..write('frozenAmount: $frozenAmount, ')
          ..write('frozenBase: $frozenBase, ')
          ..write('freezeDate: $freezeDate, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('allowanceSection: $allowanceSection')
          ..write(')'))
        .toString();
  }
}

class $PayrollRecordsTable extends PayrollRecords
    with TableInfo<$PayrollRecordsTable, PayrollRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employees (id)',
    ),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseSalaryMeta = const VerificationMeta(
    'baseSalary',
  );
  @override
  late final GeneratedColumn<double> baseSalary = GeneratedColumn<double>(
    'base_salary',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAllowancesMeta = const VerificationMeta(
    'totalAllowances',
  );
  @override
  late final GeneratedColumn<double> totalAllowances = GeneratedColumn<double>(
    'total_allowances',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDeductionsMeta = const VerificationMeta(
    'totalDeductions',
  );
  @override
  late final GeneratedColumn<double> totalDeductions = GeneratedColumn<double>(
    'total_deductions',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netSalaryMeta = const VerificationMeta(
    'netSalary',
  );
  @override
  late final GeneratedColumn<double> netSalary = GeneratedColumn<double>(
    'net_salary',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salarySnapshotMeta = const VerificationMeta(
    'salarySnapshot',
  );
  @override
  late final GeneratedColumn<String> salarySnapshot = GeneratedColumn<String>(
    'salary_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<String> processedAt = GeneratedColumn<String>(
    'processed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employeeId,
    month,
    year,
    baseSalary,
    totalAllowances,
    totalDeductions,
    netSalary,
    salarySnapshot,
    isLocked,
    processedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payroll_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayrollRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('base_salary')) {
      context.handle(
        _baseSalaryMeta,
        baseSalary.isAcceptableOrUnknown(data['base_salary']!, _baseSalaryMeta),
      );
    } else if (isInserting) {
      context.missing(_baseSalaryMeta);
    }
    if (data.containsKey('total_allowances')) {
      context.handle(
        _totalAllowancesMeta,
        totalAllowances.isAcceptableOrUnknown(
          data['total_allowances']!,
          _totalAllowancesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAllowancesMeta);
    }
    if (data.containsKey('total_deductions')) {
      context.handle(
        _totalDeductionsMeta,
        totalDeductions.isAcceptableOrUnknown(
          data['total_deductions']!,
          _totalDeductionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDeductionsMeta);
    }
    if (data.containsKey('net_salary')) {
      context.handle(
        _netSalaryMeta,
        netSalary.isAcceptableOrUnknown(data['net_salary']!, _netSalaryMeta),
      );
    } else if (isInserting) {
      context.missing(_netSalaryMeta);
    }
    if (data.containsKey('salary_snapshot')) {
      context.handle(
        _salarySnapshotMeta,
        salarySnapshot.isAcceptableOrUnknown(
          data['salary_snapshot']!,
          _salarySnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salarySnapshotMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employee_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      baseSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_salary'],
      )!,
      totalAllowances: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_allowances'],
      )!,
      totalDeductions: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_deductions'],
      )!,
      netSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_salary'],
      )!,
      salarySnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary_snapshot'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processed_at'],
      )!,
    );
  }

  @override
  $PayrollRecordsTable createAlias(String alias) {
    return $PayrollRecordsTable(attachedDatabase, alias);
  }
}

class PayrollRecord extends DataClass implements Insertable<PayrollRecord> {
  final int id;
  final int employeeId;
  final int month;
  final int year;
  final double baseSalary;
  final double totalAllowances;
  final double totalDeductions;
  final double netSalary;
  final String salarySnapshot;
  final bool isLocked;
  final String processedAt;
  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.netSalary,
    required this.salarySnapshot,
    required this.isLocked,
    required this.processedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['base_salary'] = Variable<double>(baseSalary);
    map['total_allowances'] = Variable<double>(totalAllowances);
    map['total_deductions'] = Variable<double>(totalDeductions);
    map['net_salary'] = Variable<double>(netSalary);
    map['salary_snapshot'] = Variable<String>(salarySnapshot);
    map['is_locked'] = Variable<bool>(isLocked);
    map['processed_at'] = Variable<String>(processedAt);
    return map;
  }

  PayrollRecordsCompanion toCompanion(bool nullToAbsent) {
    return PayrollRecordsCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      month: Value(month),
      year: Value(year),
      baseSalary: Value(baseSalary),
      totalAllowances: Value(totalAllowances),
      totalDeductions: Value(totalDeductions),
      netSalary: Value(netSalary),
      salarySnapshot: Value(salarySnapshot),
      isLocked: Value(isLocked),
      processedAt: Value(processedAt),
    );
  }

  factory PayrollRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollRecord(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      baseSalary: serializer.fromJson<double>(json['baseSalary']),
      totalAllowances: serializer.fromJson<double>(json['totalAllowances']),
      totalDeductions: serializer.fromJson<double>(json['totalDeductions']),
      netSalary: serializer.fromJson<double>(json['netSalary']),
      salarySnapshot: serializer.fromJson<String>(json['salarySnapshot']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      processedAt: serializer.fromJson<String>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'baseSalary': serializer.toJson<double>(baseSalary),
      'totalAllowances': serializer.toJson<double>(totalAllowances),
      'totalDeductions': serializer.toJson<double>(totalDeductions),
      'netSalary': serializer.toJson<double>(netSalary),
      'salarySnapshot': serializer.toJson<String>(salarySnapshot),
      'isLocked': serializer.toJson<bool>(isLocked),
      'processedAt': serializer.toJson<String>(processedAt),
    };
  }

  PayrollRecord copyWith({
    int? id,
    int? employeeId,
    int? month,
    int? year,
    double? baseSalary,
    double? totalAllowances,
    double? totalDeductions,
    double? netSalary,
    String? salarySnapshot,
    bool? isLocked,
    String? processedAt,
  }) => PayrollRecord(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    month: month ?? this.month,
    year: year ?? this.year,
    baseSalary: baseSalary ?? this.baseSalary,
    totalAllowances: totalAllowances ?? this.totalAllowances,
    totalDeductions: totalDeductions ?? this.totalDeductions,
    netSalary: netSalary ?? this.netSalary,
    salarySnapshot: salarySnapshot ?? this.salarySnapshot,
    isLocked: isLocked ?? this.isLocked,
    processedAt: processedAt ?? this.processedAt,
  );
  PayrollRecord copyWithCompanion(PayrollRecordsCompanion data) {
    return PayrollRecord(
      id: data.id.present ? data.id.value : this.id,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      baseSalary: data.baseSalary.present
          ? data.baseSalary.value
          : this.baseSalary,
      totalAllowances: data.totalAllowances.present
          ? data.totalAllowances.value
          : this.totalAllowances,
      totalDeductions: data.totalDeductions.present
          ? data.totalDeductions.value
          : this.totalDeductions,
      netSalary: data.netSalary.present ? data.netSalary.value : this.netSalary,
      salarySnapshot: data.salarySnapshot.present
          ? data.salarySnapshot.value
          : this.salarySnapshot,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollRecord(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('totalAllowances: $totalAllowances, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('netSalary: $netSalary, ')
          ..write('salarySnapshot: $salarySnapshot, ')
          ..write('isLocked: $isLocked, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    month,
    year,
    baseSalary,
    totalAllowances,
    totalDeductions,
    netSalary,
    salarySnapshot,
    isLocked,
    processedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollRecord &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.month == this.month &&
          other.year == this.year &&
          other.baseSalary == this.baseSalary &&
          other.totalAllowances == this.totalAllowances &&
          other.totalDeductions == this.totalDeductions &&
          other.netSalary == this.netSalary &&
          other.salarySnapshot == this.salarySnapshot &&
          other.isLocked == this.isLocked &&
          other.processedAt == this.processedAt);
}

class PayrollRecordsCompanion extends UpdateCompanion<PayrollRecord> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<int> month;
  final Value<int> year;
  final Value<double> baseSalary;
  final Value<double> totalAllowances;
  final Value<double> totalDeductions;
  final Value<double> netSalary;
  final Value<String> salarySnapshot;
  final Value<bool> isLocked;
  final Value<String> processedAt;
  const PayrollRecordsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.totalAllowances = const Value.absent(),
    this.totalDeductions = const Value.absent(),
    this.netSalary = const Value.absent(),
    this.salarySnapshot = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.processedAt = const Value.absent(),
  });
  PayrollRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required int month,
    required int year,
    required double baseSalary,
    required double totalAllowances,
    required double totalDeductions,
    required double netSalary,
    required String salarySnapshot,
    this.isLocked = const Value.absent(),
    required String processedAt,
  }) : employeeId = Value(employeeId),
       month = Value(month),
       year = Value(year),
       baseSalary = Value(baseSalary),
       totalAllowances = Value(totalAllowances),
       totalDeductions = Value(totalDeductions),
       netSalary = Value(netSalary),
       salarySnapshot = Value(salarySnapshot),
       processedAt = Value(processedAt);
  static Insertable<PayrollRecord> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<int>? month,
    Expression<int>? year,
    Expression<double>? baseSalary,
    Expression<double>? totalAllowances,
    Expression<double>? totalDeductions,
    Expression<double>? netSalary,
    Expression<String>? salarySnapshot,
    Expression<bool>? isLocked,
    Expression<String>? processedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (totalAllowances != null) 'total_allowances': totalAllowances,
      if (totalDeductions != null) 'total_deductions': totalDeductions,
      if (netSalary != null) 'net_salary': netSalary,
      if (salarySnapshot != null) 'salary_snapshot': salarySnapshot,
      if (isLocked != null) 'is_locked': isLocked,
      if (processedAt != null) 'processed_at': processedAt,
    });
  }

  PayrollRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? employeeId,
    Value<int>? month,
    Value<int>? year,
    Value<double>? baseSalary,
    Value<double>? totalAllowances,
    Value<double>? totalDeductions,
    Value<double>? netSalary,
    Value<String>? salarySnapshot,
    Value<bool>? isLocked,
    Value<String>? processedAt,
  }) {
    return PayrollRecordsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      month: month ?? this.month,
      year: year ?? this.year,
      baseSalary: baseSalary ?? this.baseSalary,
      totalAllowances: totalAllowances ?? this.totalAllowances,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      salarySnapshot: salarySnapshot ?? this.salarySnapshot,
      isLocked: isLocked ?? this.isLocked,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (baseSalary.present) {
      map['base_salary'] = Variable<double>(baseSalary.value);
    }
    if (totalAllowances.present) {
      map['total_allowances'] = Variable<double>(totalAllowances.value);
    }
    if (totalDeductions.present) {
      map['total_deductions'] = Variable<double>(totalDeductions.value);
    }
    if (netSalary.present) {
      map['net_salary'] = Variable<double>(netSalary.value);
    }
    if (salarySnapshot.present) {
      map['salary_snapshot'] = Variable<String>(salarySnapshot.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<String>(processedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayrollRecordsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('totalAllowances: $totalAllowances, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('netSalary: $netSalary, ')
          ..write('salarySnapshot: $salarySnapshot, ')
          ..write('isLocked: $isLocked, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $SalaryComponentsTable salaryComponents = $SalaryComponentsTable(
    this,
  );
  late final $PayrollRecordsTable payrollRecords = $PayrollRecordsTable(this);
  late final AppSettingsDao appSettingsDao = AppSettingsDao(
    this as AppDatabase,
  );
  late final EmployeesDao employeesDao = EmployeesDao(this as AppDatabase);
  late final SalaryComponentsDao salaryComponentsDao = SalaryComponentsDao(
    this as AppDatabase,
  );
  late final PayrollRecordsDao payrollRecordsDao = PayrollRecordsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    employees,
    salaryComponents,
    payrollRecords,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String passwordHash,
      required String securityQuestion,
      required String securityAnswerHash,
      Value<String> themeMode,
      Value<int> backupReminderDays,
      Value<String?> lastBackupDate,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> passwordHash,
      Value<String> securityQuestion,
      Value<String> securityAnswerHash,
      Value<String> themeMode,
      Value<int> backupReminderDays,
      Value<String?> lastBackupDate,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get securityQuestion => $composableBuilder(
    column: $table.securityQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get securityAnswerHash => $composableBuilder(
    column: $table.securityAnswerHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backupReminderDays => $composableBuilder(
    column: $table.backupReminderDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastBackupDate => $composableBuilder(
    column: $table.lastBackupDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get securityQuestion => $composableBuilder(
    column: $table.securityQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get securityAnswerHash => $composableBuilder(
    column: $table.securityAnswerHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backupReminderDays => $composableBuilder(
    column: $table.backupReminderDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastBackupDate => $composableBuilder(
    column: $table.lastBackupDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get securityQuestion => $composableBuilder(
    column: $table.securityQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get securityAnswerHash => $composableBuilder(
    column: $table.securityAnswerHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get backupReminderDays => $composableBuilder(
    column: $table.backupReminderDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastBackupDate => $composableBuilder(
    column: $table.lastBackupDate,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> securityQuestion = const Value.absent(),
                Value<String> securityAnswerHash = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<int> backupReminderDays = const Value.absent(),
                Value<String?> lastBackupDate = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                passwordHash: passwordHash,
                securityQuestion: securityQuestion,
                securityAnswerHash: securityAnswerHash,
                themeMode: themeMode,
                backupReminderDays: backupReminderDays,
                lastBackupDate: lastBackupDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String passwordHash,
                required String securityQuestion,
                required String securityAnswerHash,
                Value<String> themeMode = const Value.absent(),
                Value<int> backupReminderDays = const Value.absent(),
                Value<String?> lastBackupDate = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                passwordHash: passwordHash,
                securityQuestion: securityQuestion,
                securityAnswerHash: securityAnswerHash,
                themeMode: themeMode,
                backupReminderDays: backupReminderDays,
                lastBackupDate: lastBackupDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$EmployeesTableCreateCompanionBuilder =
    EmployeesCompanion Function({
      Value<int> id,
      required String employeeId,
      required String fullName,
      required String designation,
      required String department,
      Value<String?> bpsGrade,
      Value<String?> contactNumber,
      Value<String?> cnic,
      required String joiningDate,
      Value<String?> leavingDate,
      required String status,
      required String category,
      Value<double> baseSalary,
      required String createdAt,
    });
typedef $$EmployeesTableUpdateCompanionBuilder =
    EmployeesCompanion Function({
      Value<int> id,
      Value<String> employeeId,
      Value<String> fullName,
      Value<String> designation,
      Value<String> department,
      Value<String?> bpsGrade,
      Value<String?> contactNumber,
      Value<String?> cnic,
      Value<String> joiningDate,
      Value<String?> leavingDate,
      Value<String> status,
      Value<String> category,
      Value<double> baseSalary,
      Value<String> createdAt,
    });

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, Employee> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalaryComponentsTable, List<SalaryComponent>>
  _salaryComponentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.salaryComponents,
    aliasName: 'employees__id__salary_components__employee_id',
  );

  $$SalaryComponentsTableProcessedTableManager get salaryComponentsRefs {
    final manager = $$SalaryComponentsTableTableManager(
      $_db,
      $_db.salaryComponents,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _salaryComponentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PayrollRecordsTable, List<PayrollRecord>>
  _payrollRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.payrollRecords,
    aliasName: 'employees__id__payroll_records__employee_id',
  );

  $$PayrollRecordsTableProcessedTableManager get payrollRecordsRefs {
    final manager = $$PayrollRecordsTableTableManager(
      $_db,
      $_db.payrollRecords,
    ).filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_payrollRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
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

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bpsGrade => $composableBuilder(
    column: $table.bpsGrade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cnic => $composableBuilder(
    column: $table.cnic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> salaryComponentsRefs(
    Expression<bool> Function($$SalaryComponentsTableFilterComposer f) f,
  ) {
    final $$SalaryComponentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salaryComponents,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalaryComponentsTableFilterComposer(
            $db: $db,
            $table: $db.salaryComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> payrollRecordsRefs(
    Expression<bool> Function($$PayrollRecordsTableFilterComposer f) f,
  ) {
    final $$PayrollRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payrollRecords,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayrollRecordsTableFilterComposer(
            $db: $db,
            $table: $db.payrollRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
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

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bpsGrade => $composableBuilder(
    column: $table.bpsGrade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cnic => $composableBuilder(
    column: $table.cnic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get designation => $composableBuilder(
    column: $table.designation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bpsGrade =>
      $composableBuilder(column: $table.bpsGrade, builder: (column) => column);

  GeneratedColumn<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cnic =>
      $composableBuilder(column: $table.cnic, builder: (column) => column);

  GeneratedColumn<String> get joiningDate => $composableBuilder(
    column: $table.joiningDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get leavingDate => $composableBuilder(
    column: $table.leavingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> salaryComponentsRefs<T extends Object>(
    Expression<T> Function($$SalaryComponentsTableAnnotationComposer a) f,
  ) {
    final $$SalaryComponentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.salaryComponents,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalaryComponentsTableAnnotationComposer(
            $db: $db,
            $table: $db.salaryComponents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> payrollRecordsRefs<T extends Object>(
    Expression<T> Function($$PayrollRecordsTableAnnotationComposer a) f,
  ) {
    final $$PayrollRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payrollRecords,
      getReferencedColumn: (t) => t.employeeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PayrollRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.payrollRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmployeesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeesTable,
          Employee,
          $$EmployeesTableFilterComposer,
          $$EmployeesTableOrderingComposer,
          $$EmployeesTableAnnotationComposer,
          $$EmployeesTableCreateCompanionBuilder,
          $$EmployeesTableUpdateCompanionBuilder,
          (Employee, $$EmployeesTableReferences),
          Employee,
          PrefetchHooks Function({
            bool salaryComponentsRefs,
            bool payrollRecordsRefs,
          })
        > {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> designation = const Value.absent(),
                Value<String> department = const Value.absent(),
                Value<String?> bpsGrade = const Value.absent(),
                Value<String?> contactNumber = const Value.absent(),
                Value<String?> cnic = const Value.absent(),
                Value<String> joiningDate = const Value.absent(),
                Value<String?> leavingDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> baseSalary = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => EmployeesCompanion(
                id: id,
                employeeId: employeeId,
                fullName: fullName,
                designation: designation,
                department: department,
                bpsGrade: bpsGrade,
                contactNumber: contactNumber,
                cnic: cnic,
                joiningDate: joiningDate,
                leavingDate: leavingDate,
                status: status,
                category: category,
                baseSalary: baseSalary,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String employeeId,
                required String fullName,
                required String designation,
                required String department,
                Value<String?> bpsGrade = const Value.absent(),
                Value<String?> contactNumber = const Value.absent(),
                Value<String?> cnic = const Value.absent(),
                required String joiningDate,
                Value<String?> leavingDate = const Value.absent(),
                required String status,
                required String category,
                Value<double> baseSalary = const Value.absent(),
                required String createdAt,
              }) => EmployeesCompanion.insert(
                id: id,
                employeeId: employeeId,
                fullName: fullName,
                designation: designation,
                department: department,
                bpsGrade: bpsGrade,
                contactNumber: contactNumber,
                cnic: cnic,
                joiningDate: joiningDate,
                leavingDate: leavingDate,
                status: status,
                category: category,
                baseSalary: baseSalary,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EmployeesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({salaryComponentsRefs = false, payrollRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (salaryComponentsRefs) db.salaryComponents,
                    if (payrollRecordsRefs) db.payrollRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (salaryComponentsRefs)
                        await $_getPrefetchedData<
                          Employee,
                          $EmployeesTable,
                          SalaryComponent
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._salaryComponentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).salaryComponentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (payrollRecordsRefs)
                        await $_getPrefetchedData<
                          Employee,
                          $EmployeesTable,
                          PayrollRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EmployeesTableReferences
                              ._payrollRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployeesTableReferences(
                                db,
                                table,
                                p0,
                              ).payrollRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employeeId == item.id,
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

typedef $$EmployeesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeesTable,
      Employee,
      $$EmployeesTableFilterComposer,
      $$EmployeesTableOrderingComposer,
      $$EmployeesTableAnnotationComposer,
      $$EmployeesTableCreateCompanionBuilder,
      $$EmployeesTableUpdateCompanionBuilder,
      (Employee, $$EmployeesTableReferences),
      Employee,
      PrefetchHooks Function({
        bool salaryComponentsRefs,
        bool payrollRecordsRefs,
      })
    >;
typedef $$SalaryComponentsTableCreateCompanionBuilder =
    SalaryComponentsCompanion Function({
      Value<int> id,
      required int employeeId,
      required String name,
      required String componentType,
      required String valueType,
      required double value,
      Value<String?> classificationCode,
      Value<String> freezeMode,
      Value<double?> frozenAmount,
      Value<double?> frozenBase,
      Value<String?> freezeDate,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<String?> allowanceSection,
    });
typedef $$SalaryComponentsTableUpdateCompanionBuilder =
    SalaryComponentsCompanion Function({
      Value<int> id,
      Value<int> employeeId,
      Value<String> name,
      Value<String> componentType,
      Value<String> valueType,
      Value<double> value,
      Value<String?> classificationCode,
      Value<String> freezeMode,
      Value<double?> frozenAmount,
      Value<double?> frozenBase,
      Value<String?> freezeDate,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<String?> allowanceSection,
    });

final class $$SalaryComponentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SalaryComponentsTable, SalaryComponent> {
  $$SalaryComponentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('salary_components__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SalaryComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $SalaryComponentsTable> {
  $$SalaryComponentsTableFilterComposer({
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

  ColumnFilters<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classificationCode => $composableBuilder(
    column: $table.classificationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freezeMode => $composableBuilder(
    column: $table.freezeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frozenAmount => $composableBuilder(
    column: $table.frozenAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frozenBase => $composableBuilder(
    column: $table.frozenBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freezeDate => $composableBuilder(
    column: $table.freezeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowanceSection => $composableBuilder(
    column: $table.allowanceSection,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalaryComponentsTable> {
  $$SalaryComponentsTableOrderingComposer({
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

  ColumnOrderings<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classificationCode => $composableBuilder(
    column: $table.classificationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezeMode => $composableBuilder(
    column: $table.freezeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frozenAmount => $composableBuilder(
    column: $table.frozenAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frozenBase => $composableBuilder(
    column: $table.frozenBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freezeDate => $composableBuilder(
    column: $table.freezeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowanceSection => $composableBuilder(
    column: $table.allowanceSection,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalaryComponentsTable> {
  $$SalaryComponentsTableAnnotationComposer({
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

  GeneratedColumn<String> get componentType => $composableBuilder(
    column: $table.componentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get classificationCode => $composableBuilder(
    column: $table.classificationCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get freezeMode => $composableBuilder(
    column: $table.freezeMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frozenAmount => $composableBuilder(
    column: $table.frozenAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frozenBase => $composableBuilder(
    column: $table.frozenBase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get freezeDate => $composableBuilder(
    column: $table.freezeDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get allowanceSection => $composableBuilder(
    column: $table.allowanceSection,
    builder: (column) => column,
  );

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalaryComponentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalaryComponentsTable,
          SalaryComponent,
          $$SalaryComponentsTableFilterComposer,
          $$SalaryComponentsTableOrderingComposer,
          $$SalaryComponentsTableAnnotationComposer,
          $$SalaryComponentsTableCreateCompanionBuilder,
          $$SalaryComponentsTableUpdateCompanionBuilder,
          (SalaryComponent, $$SalaryComponentsTableReferences),
          SalaryComponent,
          PrefetchHooks Function({bool employeeId})
        > {
  $$SalaryComponentsTableTableManager(
    _$AppDatabase db,
    $SalaryComponentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalaryComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalaryComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalaryComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> employeeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> componentType = const Value.absent(),
                Value<String> valueType = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String?> classificationCode = const Value.absent(),
                Value<String> freezeMode = const Value.absent(),
                Value<double?> frozenAmount = const Value.absent(),
                Value<double?> frozenBase = const Value.absent(),
                Value<String?> freezeDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> allowanceSection = const Value.absent(),
              }) => SalaryComponentsCompanion(
                id: id,
                employeeId: employeeId,
                name: name,
                componentType: componentType,
                valueType: valueType,
                value: value,
                classificationCode: classificationCode,
                freezeMode: freezeMode,
                frozenAmount: frozenAmount,
                frozenBase: frozenBase,
                freezeDate: freezeDate,
                isActive: isActive,
                sortOrder: sortOrder,
                allowanceSection: allowanceSection,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int employeeId,
                required String name,
                required String componentType,
                required String valueType,
                required double value,
                Value<String?> classificationCode = const Value.absent(),
                Value<String> freezeMode = const Value.absent(),
                Value<double?> frozenAmount = const Value.absent(),
                Value<double?> frozenBase = const Value.absent(),
                Value<String?> freezeDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> allowanceSection = const Value.absent(),
              }) => SalaryComponentsCompanion.insert(
                id: id,
                employeeId: employeeId,
                name: name,
                componentType: componentType,
                valueType: valueType,
                value: value,
                classificationCode: classificationCode,
                freezeMode: freezeMode,
                frozenAmount: frozenAmount,
                frozenBase: frozenBase,
                freezeDate: freezeDate,
                isActive: isActive,
                sortOrder: sortOrder,
                allowanceSection: allowanceSection,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SalaryComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
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
                    if (employeeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.employeeId,
                                referencedTable:
                                    $$SalaryComponentsTableReferences
                                        ._employeeIdTable(db),
                                referencedColumn:
                                    $$SalaryComponentsTableReferences
                                        ._employeeIdTable(db)
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

typedef $$SalaryComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalaryComponentsTable,
      SalaryComponent,
      $$SalaryComponentsTableFilterComposer,
      $$SalaryComponentsTableOrderingComposer,
      $$SalaryComponentsTableAnnotationComposer,
      $$SalaryComponentsTableCreateCompanionBuilder,
      $$SalaryComponentsTableUpdateCompanionBuilder,
      (SalaryComponent, $$SalaryComponentsTableReferences),
      SalaryComponent,
      PrefetchHooks Function({bool employeeId})
    >;
typedef $$PayrollRecordsTableCreateCompanionBuilder =
    PayrollRecordsCompanion Function({
      Value<int> id,
      required int employeeId,
      required int month,
      required int year,
      required double baseSalary,
      required double totalAllowances,
      required double totalDeductions,
      required double netSalary,
      required String salarySnapshot,
      Value<bool> isLocked,
      required String processedAt,
    });
typedef $$PayrollRecordsTableUpdateCompanionBuilder =
    PayrollRecordsCompanion Function({
      Value<int> id,
      Value<int> employeeId,
      Value<int> month,
      Value<int> year,
      Value<double> baseSalary,
      Value<double> totalAllowances,
      Value<double> totalDeductions,
      Value<double> netSalary,
      Value<String> salarySnapshot,
      Value<bool> isLocked,
      Value<String> processedAt,
    });

final class $$PayrollRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $PayrollRecordsTable, PayrollRecord> {
  $$PayrollRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('payroll_records__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager(
      $_db,
      $_db.employees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PayrollRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollRecordsTable> {
  $$PayrollRecordsTableFilterComposer({
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

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAllowances => $composableBuilder(
    column: $table.totalAllowances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDeductions => $composableBuilder(
    column: $table.totalDeductions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netSalary => $composableBuilder(
    column: $table.netSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salarySnapshot => $composableBuilder(
    column: $table.salarySnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableFilterComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayrollRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollRecordsTable> {
  $$PayrollRecordsTableOrderingComposer({
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

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAllowances => $composableBuilder(
    column: $table.totalAllowances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDeductions => $composableBuilder(
    column: $table.totalDeductions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netSalary => $composableBuilder(
    column: $table.netSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salarySnapshot => $composableBuilder(
    column: $table.salarySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableOrderingComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayrollRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollRecordsTable> {
  $$PayrollRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get baseSalary => $composableBuilder(
    column: $table.baseSalary,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAllowances => $composableBuilder(
    column: $table.totalAllowances,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDeductions => $composableBuilder(
    column: $table.totalDeductions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get netSalary =>
      $composableBuilder(column: $table.netSalary, builder: (column) => column);

  GeneratedColumn<String> get salarySnapshot => $composableBuilder(
    column: $table.salarySnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employeeId,
      referencedTable: $db.employees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployeesTableAnnotationComposer(
            $db: $db,
            $table: $db.employees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PayrollRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PayrollRecordsTable,
          PayrollRecord,
          $$PayrollRecordsTableFilterComposer,
          $$PayrollRecordsTableOrderingComposer,
          $$PayrollRecordsTableAnnotationComposer,
          $$PayrollRecordsTableCreateCompanionBuilder,
          $$PayrollRecordsTableUpdateCompanionBuilder,
          (PayrollRecord, $$PayrollRecordsTableReferences),
          PayrollRecord,
          PrefetchHooks Function({bool employeeId})
        > {
  $$PayrollRecordsTableTableManager(
    _$AppDatabase db,
    $PayrollRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayrollRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayrollRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> employeeId = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<double> baseSalary = const Value.absent(),
                Value<double> totalAllowances = const Value.absent(),
                Value<double> totalDeductions = const Value.absent(),
                Value<double> netSalary = const Value.absent(),
                Value<String> salarySnapshot = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String> processedAt = const Value.absent(),
              }) => PayrollRecordsCompanion(
                id: id,
                employeeId: employeeId,
                month: month,
                year: year,
                baseSalary: baseSalary,
                totalAllowances: totalAllowances,
                totalDeductions: totalDeductions,
                netSalary: netSalary,
                salarySnapshot: salarySnapshot,
                isLocked: isLocked,
                processedAt: processedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int employeeId,
                required int month,
                required int year,
                required double baseSalary,
                required double totalAllowances,
                required double totalDeductions,
                required double netSalary,
                required String salarySnapshot,
                Value<bool> isLocked = const Value.absent(),
                required String processedAt,
              }) => PayrollRecordsCompanion.insert(
                id: id,
                employeeId: employeeId,
                month: month,
                year: year,
                baseSalary: baseSalary,
                totalAllowances: totalAllowances,
                totalDeductions: totalDeductions,
                netSalary: netSalary,
                salarySnapshot: salarySnapshot,
                isLocked: isLocked,
                processedAt: processedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PayrollRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
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
                    if (employeeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.employeeId,
                                referencedTable: $$PayrollRecordsTableReferences
                                    ._employeeIdTable(db),
                                referencedColumn:
                                    $$PayrollRecordsTableReferences
                                        ._employeeIdTable(db)
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

typedef $$PayrollRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PayrollRecordsTable,
      PayrollRecord,
      $$PayrollRecordsTableFilterComposer,
      $$PayrollRecordsTableOrderingComposer,
      $$PayrollRecordsTableAnnotationComposer,
      $$PayrollRecordsTableCreateCompanionBuilder,
      $$PayrollRecordsTableUpdateCompanionBuilder,
      (PayrollRecord, $$PayrollRecordsTableReferences),
      PayrollRecord,
      PrefetchHooks Function({bool employeeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$SalaryComponentsTableTableManager get salaryComponents =>
      $$SalaryComponentsTableTableManager(_db, _db.salaryComponents);
  $$PayrollRecordsTableTableManager get payrollRecords =>
      $$PayrollRecordsTableTableManager(_db, _db.payrollRecords);
}
