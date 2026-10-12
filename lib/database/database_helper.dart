import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/ipo.dart';
import '../models/application.dart';
import '../models/registrar.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipo_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adds tracking for IPOs pulled in via the IPO Guru API sync, so a
      // re-sync updates the existing row instead of creating a duplicate.
      await db.execute('ALTER TABLE ipos ADD COLUMN externalSlug TEXT');
    }
    if (oldVersion < 3) {
      // Grey Market Premium — an unofficial market rumour the user can
      // enter manually or pull in via sync; never treated as verified data.
      await db.execute('ALTER TABLE ipos ADD COLUMN gmp TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accountHolderName TEXT NOT NULL,
        accountNickname TEXT NOT NULL,
        panNumber TEXT NOT NULL UNIQUE,
        dpId TEXT,
        clientId TEXT,
        brokerName TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // IPOs Table
    await db.execute('''
      CREATE TABLE ipos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        companyName TEXT NOT NULL,
        ipoType TEXT NOT NULL,
        priceBand TEXT NOT NULL,
        openDate TEXT NOT NULL,
        closeDate TEXT NOT NULL,
        allotmentDate TEXT,
        listingDate TEXT,
        registrarName TEXT,
        registrarUrl TEXT,
        ipoStatus TEXT NOT NULL,
        notes TEXT,
        externalSlug TEXT,
        gmp TEXT
      )
    ''');

    // Applications Table (Account x IPO matrix)
    await db.execute('''
      CREATE TABLE applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ipoId INTEGER NOT NULL,
        accountId INTEGER NOT NULL,
        hasApplied INTEGER NOT NULL DEFAULT 0,
        lotsApplied INTEGER NOT NULL DEFAULT 1,
        applicationStatus TEXT NOT NULL,
        allotmentStatus TEXT NOT NULL,
        sharesAllotted INTEGER NOT NULL DEFAULT 0,
        applicationDate TEXT,
        notes TEXT,
        FOREIGN KEY (ipoId) REFERENCES ipos (id) ON DELETE CASCADE,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
        UNIQUE (ipoId, accountId)
      )
    ''');

    // Registrars Table
    await db.execute('''
      CREATE TABLE registrars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        url TEXT NOT NULL
      )
    ''');

    // Insert Default Registrars
    await _insertDefaultRegistrars(db);
  }

  Future<void> _insertDefaultRegistrars(Database db) async {
    final defaultRegistrars = [
      Registrar(name: 'Link Intime India', url: 'https://linkintime.co.in/initial_offer/public-issues.html'),
      Registrar(name: 'KFin Technologies', url: 'https://ris.kfintech.com/ipostatus/'),
      Registrar(name: 'Bigshare Services', url: 'https://www.bigshareonline.com/ipo_status.html'),
      Registrar(name: 'Skyline Financial', url: 'https://www.skylinefta.com/ipo_status.php'),
      Registrar(name: 'Cameo Corporate Services', url: 'https://ipo.cameoindia.com/'),
      Registrar(name: 'Purva Sharegistry', url: 'https://www.purvashare.com/queries/'),
    ];

    for (var reg in defaultRegistrars) {
      await db.insert('registrars', reg.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ================= ACCOUNTS CRUD =================

  Future<int> insertAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'accountHolderName ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<Account?> getAccountById(int id) async {
    final db = await instance.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= IPOS CRUD =================

  Future<int> insertIpo(Ipo ipo) async {
    final db = await instance.database;
    return await db.insert('ipos', ipo.toMap());
  }

  Future<List<Ipo>> getAllIpos() async {
    final db = await instance.database;
    final result = await db.query('ipos', orderBy: 'closeDate DESC');
    return result.map((json) => Ipo.fromMap(json)).toList();
  }

  Future<Ipo?> getIpoById(int id) async {
    final db = await instance.database;
    final maps = await db.query('ipos', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Ipo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateIpo(Ipo ipo) async {
    final db = await instance.database;
    return await db.update(
      'ipos',
      ipo.toMap(),
      where: 'id = ?',
      whereArgs: [ipo.id],
    );
  }

  Future<int> deleteIpo(int id) async {
    final db = await instance.database;
    return await db.delete(
      'ipos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Ipo?> getIpoByExternalSlug(String slug) async {
    final db = await instance.database;
    final maps = await db.query('ipos', where: 'externalSlug = ?', whereArgs: [slug]);
    if (maps.isNotEmpty) {
      return Ipo.fromMap(maps.first);
    }
    return null;
  }

  // ================= APPLICATIONS CRUD =================

  Future<int> insertOrUpdateApplication(IpoApplication application) async {
    final db = await instance.database;
    if (application.id != null) {
      return await db.update(
        'applications',
        application.toMap(),
        where: 'id = ?',
        whereArgs: [application.id],
      );
    } else {
      // Check existing by ipoId & accountId
      final existing = await db.query(
        'applications',
        where: 'ipoId = ? AND accountId = ?',
        whereArgs: [application.ipoId, application.accountId],
      );
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        final updatedApp = application.copyWith(id: existingId);
        return await db.update(
          'applications',
          updatedApp.toMap(),
          where: 'id = ?',
          whereArgs: [existingId],
        );
      } else {
        return await db.insert('applications', application.toMap());
      }
    }
  }

  Future<List<IpoApplication>> getAllApplications() async {
    final db = await instance.database;
    final result = await db.query('applications');
    return result.map((json) => IpoApplication.fromMap(json)).toList();
  }

  Future<List<IpoApplication>> getApplicationsForIpo(int ipoId) async {
    final db = await instance.database;
    final result = await db.query(
      'applications',
      where: 'ipoId = ?',
      whereArgs: [ipoId],
    );
    return result.map((json) => IpoApplication.fromMap(json)).toList();
  }

  Future<List<IpoApplication>> getApplicationsForAccount(int accountId) async {
    final db = await instance.database;
    final result = await db.query(
      'applications',
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
    return result.map((json) => IpoApplication.fromMap(json)).toList();
  }

  Future<IpoApplication?> getApplication(int ipoId, int accountId) async {
    final db = await instance.database;
    final maps = await db.query(
      'applications',
      where: 'ipoId = ? AND accountId = ?',
      whereArgs: [ipoId, accountId],
    );
    if (maps.isNotEmpty) {
      return IpoApplication.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteApplication(int id) async {
    final db = await instance.database;
    return await db.delete(
      'applications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= REGISTRARS CRUD =================

  Future<int> insertRegistrar(Registrar registrar) async {
    final db = await instance.database;
    return await db.insert('registrars', registrar.toMap());
  }

  Future<List<Registrar>> getAllRegistrars() async {
    final db = await instance.database;
    final result = await db.query('registrars', orderBy: 'name ASC');
    return result.map((json) => Registrar.fromMap(json)).toList();
  }

  Future<int> updateRegistrar(Registrar registrar) async {
    final db = await instance.database;
    return await db.update(
      'registrars',
      registrar.toMap(),
      where: 'id = ?',
      whereArgs: [registrar.id],
    );
  }

  Future<int> deleteRegistrar(int id) async {
    final db = await instance.database;
    return await db.delete(
      'registrars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= SEED SAMPLE DATA =================

  Future<void> seedSampleData() async {
    // Check if sample accounts already exist
    final accounts = await getAllAccounts();
    if (accounts.isEmpty) {
      final acc1 = Account(
        accountHolderName: 'Rahul Sharma',
        accountNickname: 'My Account',
        panNumber: 'ABCDE1234F',
        dpId: '12081600',
        clientId: '01234567',
        brokerName: 'Zerodha',
        notes: 'Primary trading account',
      );
      final acc2 = Account(
        accountHolderName: 'Suresh Sharma',
        accountNickname: 'Father',
        panNumber: 'FGHIJ5678K',
        dpId: '12081600',
        clientId: '07654321',
        brokerName: 'Groww',
        notes: 'Father demat account',
      );
      final acc3 = Account(
        accountHolderName: 'Pooja Sharma',
        accountNickname: 'Mother',
        panNumber: 'LMNOP9012Q',
        dpId: 'IN301549',
        clientId: '10987654',
        brokerName: 'Angel One',
        notes: 'Mother demat account',
      );

      final acc1Id = await insertAccount(acc1);
      final acc2Id = await insertAccount(acc2);
      await insertAccount(acc3);

      final now = DateTime.now();
      final openSample = now.subtract(const Duration(days: 1)).toIso8601String().split('T').first;
      final closeSample = now.add(const Duration(days: 2)).toIso8601String().split('T').first;
      final allotmentSample = now.add(const Duration(days: 5)).toIso8601String().split('T').first;
      final listingSample = now.add(const Duration(days: 8)).toIso8601String().split('T').first;

      final ipo1 = Ipo(
        companyName: 'Sample IPO Alpha Ltd',
        ipoType: 'Mainboard',
        priceBand: '₹450 - ₹475',
        openDate: openSample,
        closeDate: closeSample,
        allotmentDate: allotmentSample,
        listingDate: listingSample,
        registrarName: 'Link Intime India',
        registrarUrl: 'https://linkintime.co.in/initial_offer/public-issues.html',
        ipoStatus: 'OPEN',
        notes: 'Sample technology IPO',
      );

      final ipo2 = Ipo(
        companyName: 'Sample IPO Beta SME',
        ipoType: 'SME',
        priceBand: '₹120 - ₹125',
        openDate: now.add(const Duration(days: 4)).toIso8601String().split('T').first,
        closeDate: now.add(const Duration(days: 7)).toIso8601String().split('T').first,
        allotmentDate: now.add(const Duration(days: 10)).toIso8601String().split('T').first,
        listingDate: now.add(const Duration(days: 14)).toIso8601String().split('T').first,
        registrarName: 'KFin Technologies',
        registrarUrl: 'https://ris.kfintech.com/ipostatus/',
        ipoStatus: 'UPCOMING',
        notes: 'Sample SME manufacturing IPO',
      );

      final ipo1Id = await insertIpo(ipo1);
      await insertIpo(ipo2);

      // Seed application entries for IPO Alpha
      await insertOrUpdateApplication(IpoApplication(
        ipoId: ipo1Id,
        accountId: acc1Id,
        hasApplied: true,
        lotsApplied: 1,
        applicationStatus: 'SUBMITTED',
        allotmentStatus: 'PENDING',
        applicationDate: openSample,
      ));

      await insertOrUpdateApplication(IpoApplication(
        ipoId: ipo1Id,
        accountId: acc2Id,
        hasApplied: true,
        lotsApplied: 2,
        applicationStatus: 'SUBMITTED',
        allotmentStatus: 'PENDING',
        applicationDate: openSample,
      ));
    }
  }
}
