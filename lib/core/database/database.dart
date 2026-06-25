import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ════════════════════════════════ TABLES ════════════════════════════════════

class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get passwordHash => text()();
  TextColumn get securityQuestion => text()();
  TextColumn get securityAnswerHash => text()();
  TextColumn get themeMode => text().withDefault(const Constant('light'))();
  IntColumn get backupReminderDays => integer().withDefault(const Constant(7))();
  TextColumn get lastBackupDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get employeeId => text()();
  TextColumn get fullName => text()();
  TextColumn get designation => text()();
  TextColumn get department => text()();
  TextColumn get bpsGrade => text().nullable()();
  TextColumn get contactNumber => text().nullable()();
  TextColumn get cnic => text().nullable()();
  TextColumn get joiningDate => text()();
  TextColumn get leavingDate => text().nullable()();
  // 'active' or 'left'
  TextColumn get status => text()();
  // 'pedo', 'security', 'alfajar'
  TextColumn get category => text()();
  RealColumn get baseSalary => real().withDefault(const Constant(0.0))();
  TextColumn get createdAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {employeeId, category},
  ];
}

class SalaryComponents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get name => text()();
  // 'allowance' or 'deduction'
  TextColumn get componentType => text()();
  // 'percentage' or 'fixed'
  TextColumn get valueType => text()();
  RealColumn get value => real()();
  TextColumn get classificationCode => text().nullable()();
  // 'not_frozen', 'frozen_on_amount', 'frozen_on_base'
  TextColumn get freezeMode =>
      text().withDefault(const Constant('not_frozen'))();
  RealColumn get frozenAmount => real().nullable()();
  RealColumn get frozenBase => real().nullable()();
  TextColumn get freezeDate => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // 'regular' or 'other' for pedo allowances; null for deductions and non-pedo
  TextColumn get allowanceSection => text().nullable()();
}

class PayrollRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get baseSalary => real()();
  RealColumn get totalAllowances => real()();
  RealColumn get totalDeductions => real()();
  RealColumn get netSalary => real()();
  // Full salary breakdown as JSON
  TextColumn get salarySnapshot => text()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get processedAt => text()();
}

// ════════════════════════════════ DAOs ══════════════════════════════════════

@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<AppSetting?> getSettings() =>
      (select(appSettings)..where((t) => t.id.equals(1))).getSingleOrNull();

  Future<void> upsertSettings(AppSettingsCompanion settings) =>
      into(appSettings).insertOnConflictUpdate(settings);

  Future<void> updateBackupReminder(int days) async {
    final s = await getSettings();
    if (s == null) return;
    await upsertSettings(AppSettingsCompanion(
      id: const Value(1),
      passwordHash: Value(s.passwordHash),
      securityQuestion: Value(s.securityQuestion),
      securityAnswerHash: Value(s.securityAnswerHash),
      themeMode: Value(s.themeMode),
      backupReminderDays: Value(days),
      lastBackupDate: Value(s.lastBackupDate),
    ));
  }

  Future<void> updateLastBackupDate(String date) async {
    final s = await getSettings();
    if (s == null) return;
    await upsertSettings(AppSettingsCompanion(
      id: const Value(1),
      passwordHash: Value(s.passwordHash),
      securityQuestion: Value(s.securityQuestion),
      securityAnswerHash: Value(s.securityAnswerHash),
      themeMode: Value(s.themeMode),
      backupReminderDays: Value(s.backupReminderDays),
      lastBackupDate: Value(date),
    ));
  }
}

@DriftAccessor(tables: [Employees])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  Future<List<Employee>> getAllEmployees() => select(employees).get();

  Future<List<Employee>> getEmployeesByCategory(String category) =>
      (select(employees)..where((t) => t.category.equals(category))).get();

  Future<List<Employee>> getActiveEmployees() =>
      (select(employees)..where((t) => t.status.equals('active'))).get();

  Future<Employee?> getEmployeeById(int id) =>
      (select(employees)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);

  Future<bool> updateEmployee(Employee employee) =>
      update(employees).replace(employee);

  Future<int> deleteEmployee(int id) =>
      (delete(employees)..where((t) => t.id.equals(id))).go();

  Stream<List<Employee>> watchAllEmployees() => select(employees).watch();

  Stream<List<Employee>> watchEmployeesByCategory(String category) =>
      (select(employees)..where((t) => t.category.equals(category))).watch();
}

@DriftAccessor(tables: [SalaryComponents])
class SalaryComponentsDao extends DatabaseAccessor<AppDatabase>
    with _$SalaryComponentsDaoMixin {
  SalaryComponentsDao(super.db);

  Future<List<SalaryComponent>> getComponentsByEmployee(int employeeId) =>
      (select(salaryComponents)
            ..where((t) => t.employeeId.equals(employeeId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<List<SalaryComponent>> getActiveComponentsByEmployee(
    int employeeId,
  ) =>
      (select(salaryComponents)
            ..where(
              (t) =>
                  t.employeeId.equals(employeeId) & t.isActive.equals(true),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  Future<int> insertComponent(SalaryComponentsCompanion component) =>
      into(salaryComponents).insert(component);

  Future<bool> updateComponent(SalaryComponent component) =>
      update(salaryComponents).replace(component);

  Future<int> deleteComponent(int id) =>
      (delete(salaryComponents)..where((t) => t.id.equals(id))).go();

  Future<int> deleteComponentsByEmployee(int employeeId) =>
      (delete(salaryComponents)
            ..where((t) => t.employeeId.equals(employeeId)))
          .go();

  Future<List<SalaryComponent>> getAllComponents() =>
      select(salaryComponents).get();

  Stream<List<SalaryComponent>> watchComponentsByEmployee(int employeeId) =>
      (select(salaryComponents)
            ..where((t) => t.employeeId.equals(employeeId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();
}

@DriftAccessor(tables: [PayrollRecords])
class PayrollRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$PayrollRecordsDaoMixin {
  PayrollRecordsDao(super.db);

  Future<List<PayrollRecord>> getRecordsByEmployee(int employeeId) =>
      (select(payrollRecords)
            ..where((t) => t.employeeId.equals(employeeId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.year, mode: OrderingMode.desc),
              (t) => OrderingTerm(expression: t.month, mode: OrderingMode.desc),
            ]))
          .get();

  Future<List<PayrollRecord>> getRecordsByMonthYear(int month, int year) =>
      (select(payrollRecords)
            ..where((t) => t.month.equals(month) & t.year.equals(year)))
          .get();

  Stream<List<PayrollRecord>> watchRecordsByMonthYear(int month, int year) =>
      (select(payrollRecords)
            ..where((t) => t.month.equals(month) & t.year.equals(year)))
          .watch();

  Future<PayrollRecord?> getRecord(int employeeId, int month, int year) =>
      (select(payrollRecords)
            ..where(
              (t) =>
                  t.employeeId.equals(employeeId) &
                  t.month.equals(month) &
                  t.year.equals(year),
            ))
          .getSingleOrNull();

  /// Insert or replace — safe to call even when a record already exists for
  /// the same (employeeId, month, year) thanks to the unique index added in
  /// schema version 2.
  Future<int> upsertRecord(PayrollRecordsCompanion record) =>
      into(payrollRecords).insertOnConflictUpdate(record);

  Future<int> insertRecord(PayrollRecordsCompanion record) =>
      into(payrollRecords).insert(record);

  Future<bool> updateRecord(PayrollRecord record) =>
      update(payrollRecords).replace(record);

  Future<int> lockRecord(int id) =>
      (update(payrollRecords)..where((t) => t.id.equals(id)))
          .write(const PayrollRecordsCompanion(isLocked: Value(true)));

  Future<int> unlockRecord(int id) =>
      (update(payrollRecords)..where((t) => t.id.equals(id)))
          .write(const PayrollRecordsCompanion(isLocked: Value(false)));

  Future<int> deleteRecord(int id) =>
      (delete(payrollRecords)..where((t) => t.id.equals(id))).go();

  Future<int> deleteRecordsByEmployee(int employeeId) =>
      (delete(payrollRecords)..where((t) => t.employeeId.equals(employeeId))).go();

  Future<List<PayrollRecord>> getAllRecords() => select(payrollRecords).get();
}

// ════════════════════════════ DATABASE ══════════════════════════════════════

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(dbFolder.path, 'pay_vault.sqlite');
    return SqfliteQueryExecutor(path: path, logStatements: false);
  });
}

@DriftDatabase(
  tables: [AppSettings, Employees, SalaryComponents, PayrollRecords],
  daos: [AppSettingsDao, EmployeesDao, SalaryComponentsDao, PayrollRecordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Enforce one record per employee per month/year.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_payroll_unique '
        'ON payroll_records(employee_id, month, year)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_payroll_unique '
          'ON payroll_records(employee_id, month, year)',
        );
      }
      if (from < 3) {
        await m.addColumn(salaryComponents, salaryComponents.allowanceSection);
        // Existing pedo allowances default to 'regular'
        await customStatement(
          "UPDATE salary_components SET allowance_section = 'regular' "
          "WHERE component_type = 'allowance'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> clearAll() async {
    await customStatement('DELETE FROM payroll_records');
    await customStatement('DELETE FROM salary_components');
    await customStatement('DELETE FROM employees');
  }

  /// Applies freeze logic to compute the effective value of a salary component.
  ///
  /// - `not_frozen`      → calculate fresh from [currentBaseSalary]
  /// - `frozen_on_amount` → return [SalaryComponent.frozenAmount] directly
  /// - `frozen_on_base`  → apply percentage to [SalaryComponent.frozenBase]
  double calculateSalaryComponent(
    SalaryComponent component,
    double currentBaseSalary,
  ) {
    switch (component.freezeMode) {
      case 'frozen_on_amount':
        return component.frozenAmount ?? 0.0;
      case 'frozen_on_base':
        final base = component.frozenBase ?? 0.0;
        return component.value * base / 100;
      default: // 'not_frozen'
        return component.valueType == 'percentage'
            ? currentBaseSalary * component.value / 100
            : component.value;
    }
  }
}
