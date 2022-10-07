import SQLite3
import Foundation
import Lighter

/**
 * A structure representing a SQLite database.
 *
 * ### Database Schema
 *
 * The schema captures the SQLite table/view catalog as safe Swift types.
 *
 * #### Tables
 *
 * - ``RegionUpdate`` (SQL: `region_update`)
 *
 * > Hint: Use [SQL Views](https://www.sqlite.org/lang_createview.html)
 * >       to create Swift types that represent common queries.
 * >       (E.g. joins between tables or fragments of table data.)
 *
 * ### Examples
 *
 * Perform record operations on ``RegionUpdate`` records:
 * ```swift
 * let records = try await db.regionUpdates.filter(orderBy: \.updateTypeRaw) {
 *   $0.updateTypeRaw != nil
 * }
 *
 * try await db.transaction { tx in
 *   var record = try tx.regionUpdates.find(2) // find by primaryKey
 *
 *   record.updateTypeRaw = "Hunt"
 *   try tx.update(record)
 *
 *   let newRecord = try tx.insert(record)
 *   try tx.delete(newRecord)
 * }
 * ```
 *
 * Perform column selects on the `region_update` table:
 * ```swift
 * let values = try await db.select(from: \.regionUpdates, \.updateTypeRaw) {
 *   $0.in([ 2, 3 ])
 * }
 * ```
 *
 * Perform low level operations on ``RegionUpdate`` records:
 * ```swift
 * var db : OpaquePointer?
 * sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil)
 *
 * var records = RegionUpdate.fetch(in: db, orderBy: "updateTypeRaw", limit: 5) {
 *   $0.updateTypeRaw != nil
 * }
 * records[1].updateTypeRaw = "Hunt"
 * records[1].update(in: db)
 *
 * records[0].delete(in: db])
 * records[0].insert(db) // re-add
 * ```
 */
@dynamicMemberLookup
public struct BeenOutside : SQLDatabase, SQLDatabaseAsyncChangeOperations, SQLCreationStatementsHolder {

  /**
   * Mappings of table/view Swift types to their "reference name".
   *
   * The `RecordTypes` structure contains a variable for the Swift type
   * associated each table/view of the database. It maps the tables
   * "reference names" (e.g. ``regionUpdates``) to the
   * "record type" of the table (e.g. ``RegionUpdate``.self).
   */
  public struct RecordTypes {

    /// Returns the RegionUpdate type information (SQL: `region_update`).
    public let regionUpdates = RegionUpdate.self
  }

  /// Property based access to the ``RecordTypes-swift.struct``.
  public static let recordTypes = RecordTypes()

#if swift(>=5.7)
  /// All RecordTypes defined in the database.
  public static let _allRecordTypes : [ any SQLRecord.Type ] = [ RegionUpdate.self ]
#endif // swift(>=5.7)

  /// User version of the database (`PRAGMA user_version`).
  public static var userVersion = 1

  /// Whether `INSERT … RETURNING` should be used (requires SQLite 3.35.0+).
  public static var useInsertReturning = sqlite3_libversion_number() >= 3035000

  /// The `DateFormatter` used for parsing string date values.
  static var _dateFormatter : DateFormatter?

  /// The `DateFormatter` used for parsing string date values.
  public static var dateFormatter : DateFormatter? {
    set {
      _dateFormatter = newValue
    }
    get {
      _dateFormatter ?? Date.defaultSQLiteDateFormatter
    }
  }

  /// SQL that can be used to recreate the database structure.
  @inlinable
  public static var creationSQL : String {
    var sql = ""
    sql.append(RegionUpdate.Schema.create)
    sql.append(#"PRAGMA user_version = 1);"#)
    return sql
  }

  /**
   * Create a SQLite3 database
   *
   * The database is created using the SQL `create` statements in the
   * Schema structures.
   *
   * If the operation is successful, the open database handle will be
   * returned in the `db` `inout` parameter.
   * If the open succeeds, but the SQL execution fails, an incomplete
   * database can be left behind. I.e. if an error happens, the path
   * should be tested and deleted if appropriate.
   *
   * Example:
   * ```swift
   * var db : OpaquePointer!
   * let rc = BeenOutside.create(path, in: &db)
   * ```
   *
   * - Parameters:
   *   - path: Path of the database.
   *   - flags: Custom open flags.
   *   - db: A SQLite3 database handle, if successful.
   * - Returns: The SQLite3 error code (`SQLITE_OK` on success).
   */
  @inlinable
  public static func create(
    _ path: UnsafePointer<CChar>!,
    _ flags: Int32 = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE,
    `in` db: inout OpaquePointer?
  ) -> Int32
  {
    let openrc = sqlite3_open_v2(path, &db, flags, nil)
    if openrc != SQLITE_OK {
      return openrc
    }
    let execrc = sqlite3_exec(db, BeenOutside.creationSQL, nil, nil, nil)
    if execrc != SQLITE_OK {
      sqlite3_close(db)
      db = nil
      return execrc
    }
    return SQLITE_OK
  }

  public static func withOptCString<R>(
    _ s: String?,
    _ body: ( UnsafePointer<CChar>? ) throws -> R
  ) rethrows -> R
  {
    if let s = s { return try s.withCString(body) }
    else { return try body(nil) }
  }

  /// The `connectionHandler` is used to open SQLite database connections.
  public var connectionHandler : SQLConnectionHandler

  /**
   * Initialize ``BeenOutside`` with a `URL`.
   *
   * Configures the database with a simple connection pool opening the
   * specified `URL`.
   * And optional `readOnly` flag can be set (defaults to `false`).
   *
   * Example:
   * ```swift
   * let db = BeenOutside(url: ...)
   *
   * // Write operations will raise an error.
   * let readOnly = BeenOutside(
   *   url: Bundle.module.url(forResource: "samples", withExtension: "db"),
   *   readOnly: true
   * )
   * ```
   *
   * - Parameters:
   *   - url: A `URL` pointing to the database to be used.
   *   - readOnly: Whether the database should be opened readonly (default: `false`).
   */
  @inlinable
  public init(url: URL, readOnly: Bool = false)
  {
    self.connectionHandler = .simplePool(url: url, readOnly: readOnly)
  }

  /**
   * Initialize ``BeenOutside`` w/ a `SQLConnectionHandler`.
   *
   * `SQLConnectionHandler`'s are used to open SQLite database connections when
   * queries are run using the `Lighter` APIs.
   * The `SQLConnectionHandler` is a protocol and custom handlers
   * can be provided.
   *
   * Example:
   * ```swift
   * let db = BeenOutside(connectionHandler: .simplePool(
   *   url: Bundle.module.url(forResource: "samples", withExtension: "db"),
   *   readOnly: true,
   *   maxAge: 10,
   *   maximumPoolSizePerConfiguration: 4
   * ))
   * ```
   *
   * - Parameters:
   *   - connectionHandler: The `SQLConnectionHandler` to use w/ the database.
   */
  @inlinable
  public init(connectionHandler: SQLConnectionHandler)
  {
    self.connectionHandler = connectionHandler
  }
}

/**
 * Record representing the `region_update` SQL table.
 *
 * Record types represent rows within tables&views in a SQLite database.
 * They are returned by the functions or queries/filters generated by
 * Enlighter.
 *
 * ### Examples
 *
 * Perform record operations on ``RegionUpdate`` records:
 * ```swift
 * let records = try await db.regionUpdates.filter(orderBy: \.updateTypeRaw) {
 *   $0.updateTypeRaw != nil
 * }
 *
 * try await db.transaction { tx in
 *   var record = try tx.regionUpdates.find(2) // find by primaryKey
 *
 *   record.updateTypeRaw = "Hunt"
 *   try tx.update(record)
 *
 *   let newRecord = try tx.insert(record)
 *   try tx.delete(newRecord)
 * }
 * ```
 *
 * Perform column selects on the `region_update` table:
 * ```swift
 * let values = try await db.select(from: \.regionUpdates, \.updateTypeRaw) {
 *   $0.in([ 2, 3 ])
 * }
 * ```
 *
 * Perform low level operations on ``RegionUpdate`` records:
 * ```swift
 * var db : OpaquePointer?
 * sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil)
 *
 * var records = RegionUpdate.fetch(in: db, orderBy: "updateTypeRaw", limit: 5) {
 *   $0.updateTypeRaw != nil
 * }
 * records[1].updateTypeRaw = "Hunt"
 * records[1].update(in: db)
 *
 * records[0].delete(in: db])
 * records[0].insert(db) // re-add
 * ```
 */
public struct RegionUpdate : Identifiable, SQLKeyedTableRecord, Codable {

  /// Static SQL type information for the ``RegionUpdate`` record.
  public static let schema = Schema()

  /// Primary key `region_update_id` (`INTEGER`), optional (default: `nil`).
  public var id : Int?

  /// Column `date` (`DATETIME`), required (has default).
  public var date : Date

  /// Column `update_type_raw` (`TEXT`), required (has default).
  public var updateTypeRaw : String

  /// Column `region_name` (`TEXT`), optional (default: `nil`).
  public var regionName : String?

  /**
   * Initialize a new ``RegionUpdate`` record.
   *
   * - Parameters:
   *   - id: Primary key `region_update_id` (`INTEGER`), optional (default: `nil`).
   *   - date: Column `date` (`DATETIME`), required (has default).
   *   - updateTypeRaw: Column `update_type_raw` (`TEXT`), required (has default).
   *   - regionName: Column `region_name` (`TEXT`), optional (default: `nil`).
   */
  @inlinable
  public init(
    id: Int? = nil,
    date: Date,
    updateTypeRaw: String,
    regionName: String? = nil
  )
  {
    self.id = id
    self.date = date
    self.updateTypeRaw = updateTypeRaw
    self.regionName = regionName
  }
}

public extension RegionUpdate {

  /**
   * Fetch ``RegionUpdate`` records, filtering using a Swift closure.
   *
   * This is fetching full ``RegionUpdate`` records from the passed in SQLite database
   * handle. The filtering is done within SQLite, but using a Swift closure
   * that can be passed in.
   *
   * Within that closure other SQL queries can be done on separate connections,
   * but *not* within the same database handle that is being passed in (because
   * the closure is executed in the context of the query).
   *
   * Sorting can be done using raw SQL (by passing in a `orderBy` parameter,
   * e.g. `orderBy: "name DESC"`),
   * or just in Swift (e.g. `fetch(in: db).sorted { $0.name > $1.name }`).
   * Since the matching is done in Swift anyways, the primary advantage of
   * doing it in SQL is that a `LIMIT` can be applied efficiently (i.e. w/o
   * walking and loading all rows).
   *
   * If the function returns `nil`, the error can be found using the usual
   * `sqlite3_errcode` and companions.
   *
   * Example:
   * ```swift
   * let records = RegionUpdate.fetch(in: db) { record in
   *   record.name != "Duck"
   * }
   *
   * let records = RegionUpdate.fetch(in: db, orderBy: "name", limit: 5) {
   *   $0.firstname != nil
   * }
   * ```
   *
   * - Parameters:
   *   - db: The SQLite database handle (as returned by `sqlite3_open`)
   *   - sql: Optional custom SQL yielding ``RegionUpdate`` records.
   *   - orderBySQL: If set, some SQL that is added as an `ORDER BY` clause (e.g. `name DESC`).
   *   - limit: An optional fetch limit.
   *   - filter: A Swift closure used for filtering, taking the``RegionUpdate`` record to be matched.
   * - Returns: The records matching the query, or `nil` if there was an error.
   */
  @inlinable
  static func fetch(
    from db: OpaquePointer!,
    sql customSQL: String? = nil,
    orderBy orderBySQL: String? = nil,
    limit: Int? = nil,
    filter: @escaping ( RegionUpdate ) -> Bool
  ) -> [ RegionUpdate ]?
  {
    withUnsafePointer(to: filter) { ( closurePtr ) in
      guard Schema.registerSwiftMatcher(in: db, flags: SQLITE_UTF8, matcher: closurePtr) == SQLITE_OK else {
        return nil
      }
      defer {
        RegionUpdate.Schema.unregisterSwiftMatcher(in: db, flags: SQLITE_UTF8)
      }
      var sql = customSQL ?? RegionUpdate.Schema.matchSelect
      if let orderBySQL = orderBySQL {
        sql.append(" ORDER BY \(orderBySQL)")
      }
      if let limit = limit {
        sql.append(" LIMIT \(limit)")
      }
      var handle : OpaquePointer? = nil
      guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
            let statement = handle else { return nil }
      defer { sqlite3_finalize(statement) }
      let indices = customSQL != nil ? Schema.lookupColumnIndices(in: statement) : Schema.selectColumnIndices
      var records = [ RegionUpdate ]()
      while true {
        let rc = sqlite3_step(statement)
        if rc == SQLITE_DONE {
          break
        }
        else if rc != SQLITE_ROW {
          return nil
        }
        records.append(RegionUpdate(statement, indices: indices))
      }
      return records
    }
  }

  /**
   * Fetch ``RegionUpdate`` records using the base SQLite API.
   *
   * If the function returns `nil`, the error can be found using the usual
   * `sqlite3_errcode` and companions.
   *
   * Example:
   * ```swift
   * let records = RegionUpdate.fetch(
   *   from : db,
   *   sql  : #"SELECT * FROM region_update"#
   * }
   *
   * let records = RegionUpdate.fetch(
   *   from    : db,
   *   sql     : #"SELECT * FROM region_update"#,
   *   orderBy : "name", limit: 5
   * )
   * ```
   *
   * - Parameters:
   *   - db: The SQLite database handle (as returned by `sqlite3_open`)
   *   - sql: Custom SQL yielding ``RegionUpdate`` records.
   *   - orderBySQL: If set, some SQL that is added as an `ORDER BY` clause (e.g. `name DESC`).
   *   - limit: An optional fetch limit.
   * - Returns: The records matching the query, or `nil` if there was an error.
   */
  @inlinable
  static func fetch(
    from db: OpaquePointer!,
    sql customSQL: String? = nil,
    orderBy orderBySQL: String? = nil,
    limit: Int? = nil
  ) -> [ RegionUpdate ]?
  {
    var sql = customSQL ?? RegionUpdate.Schema.select
    if let orderBySQL = orderBySQL {
      sql.append(" ORDER BY \(orderBySQL)")
    }
    if let limit = limit {
      sql.append(" LIMIT \(limit)")
    }
    var handle : OpaquePointer? = nil
    guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
          let statement = handle else { return nil }
    defer { sqlite3_finalize(statement) }
    let indices = customSQL != nil ? Schema.lookupColumnIndices(in: statement) : Schema.selectColumnIndices
    var records = [ RegionUpdate ]()
    while true {
      let rc = sqlite3_step(statement)
      if rc == SQLITE_DONE {
        break
      }
      else if rc != SQLITE_ROW {
        return nil
      }
      records.append(RegionUpdate(statement, indices: indices))
    }
    return records
  }

  /**
   * Insert a ``RegionUpdate`` record in the SQLite database.
   *
   * This operates on a raw SQLite database handle (as returned by
   * `sqlite3_open`).
   *
   * Example:
   * ```swift
   * var record = RegionUpdate(...values...)
   * let rc = record.insert(into: db)
   * assert(rc == SQLITE_OK)
   * ```
   *
   * - Parameters:
   *   - db: SQLite3 database handle.
   * - Returns: The SQLite error code (of `sqlite3_prepare/step`), e.g. `SQLITE_OK`.
   */
  @inlinable
  @discardableResult
  mutating func insert(into db: OpaquePointer!) -> Int32
  {
    let sql = BeenOutside.useInsertReturning ? RegionUpdate.Schema.insertReturning : RegionUpdate.Schema.insert
    var handle : OpaquePointer? = nil
    guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
          let statement = handle else { return sqlite3_errcode(db) }
    defer { sqlite3_finalize(statement) }
    return self.bind(to: statement, indices: RegionUpdate.Schema.insertParameterIndices) {
      let rc = sqlite3_step(statement)
      if rc == SQLITE_DONE {
        var sql = RegionUpdate.Schema.select
        sql.append(#" WHERE ROWID = last_insert_rowid()"#)
        var handle : OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
              let statement = handle else { return sqlite3_errcode(db) }
        defer { sqlite3_finalize(statement) }
        let rc = sqlite3_step(statement)
        if rc == SQLITE_DONE {
          return SQLITE_OK
        }
        else if rc != SQLITE_ROW {
          return sqlite3_errcode(db)
        }
        let record = RegionUpdate(statement, indices: RegionUpdate.Schema.selectColumnIndices)
        self = record
        return SQLITE_OK
      }
      else if rc != SQLITE_ROW {
        return sqlite3_errcode(db)
      }
      let record = RegionUpdate(statement, indices: RegionUpdate.Schema.selectColumnIndices)
      self = record
      return SQLITE_OK
    }
  }

  /**
   * Update a ``RegionUpdate`` record in the SQLite database.
   *
   * This operates on a raw SQLite database handle (as returned by
   * `sqlite3_open`).
   *
   * Example:
   * ```swift
   * let rc = record.update(in: db)
   * assert(rc == SQLITE_OK)
   * ```
   *
   * - Parameters:
   *   - db: SQLite3 database handle.
   * - Returns: The SQLite error code (of `sqlite3_prepare/step`), e.g. `SQLITE_OK`.
   */
  @inlinable
  @discardableResult
  func update(`in` db: OpaquePointer!) -> Int32
  {
    let sql = RegionUpdate.Schema.update
    var handle : OpaquePointer? = nil
    guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
          let statement = handle else { return sqlite3_errcode(db) }
    defer { sqlite3_finalize(statement) }
    return self.bind(to: statement, indices: RegionUpdate.Schema.updateParameterIndices) {
      let rc = sqlite3_step(statement)
      return rc != SQLITE_DONE && rc != SQLITE_ROW ? sqlite3_errcode(db) : SQLITE_OK
    }
  }

  /**
   * Delete a ``RegionUpdate`` record in the SQLite database.
   *
   * This operates on a raw SQLite database handle (as returned by
   * `sqlite3_open`).
   *
   * Example:
   * ```swift
   * let rc = record.delete(from: db)
   * assert(rc == SQLITE_OK)
   * ```
   *
   * - Parameters:
   *   - db: SQLite3 database handle.
   * - Returns: The SQLite error code (of `sqlite3_prepare/step`), e.g. `SQLITE_OK`.
   */
  @inlinable
  @discardableResult
  func delete(from db: OpaquePointer!) -> Int32
  {
    let sql = RegionUpdate.Schema.delete
    var handle : OpaquePointer? = nil
    guard sqlite3_prepare_v2(db, sql, -1, &handle, nil) == SQLITE_OK,
          let statement = handle else { return sqlite3_errcode(db) }
    defer { sqlite3_finalize(statement) }
    return self.bind(to: statement, indices: RegionUpdate.Schema.deleteParameterIndices) {
      let rc = sqlite3_step(statement)
      return rc != SQLITE_DONE && rc != SQLITE_ROW ? sqlite3_errcode(db) : SQLITE_OK
    }
  }
}

public extension RegionUpdate {

  /**
   * Static type information for the ``RegionUpdate`` record (`region_update` SQL table).
   *
   * This structure captures the static SQL information associated with the
   * record.
   * It is used for static type lookups and more.
   */
  struct Schema : SQLKeyedTableSchema, SQLSwiftMatchableSchema, SQLCreatableSchema {

    public typealias PropertyIndices = ( idx_id: Int32, idx_date: Int32, idx_updateTypeRaw: Int32, idx_regionName: Int32 )
    public typealias RecordType = RegionUpdate
    public typealias MatchClosureType = ( RegionUpdate ) -> Bool

    /// The SQL table name associated with the ``RegionUpdate`` record.
    public static let externalName = "region_update"

    /// The number of columns the `region_update` table has.
    public static let columnCount : Int32 = 4

    /// Information on the records primary key (``RegionUpdate/id``).
    public static let primaryKeyColumn = MappedColumn<RegionUpdate, Int?>(
      externalName: "region_update_id",
      defaultValue: nil,
      keyPath: \RegionUpdate.id
    )

    /// The SQL used to create the `region_update` table.
    public static let create =
      #"""
      CREATE TABLE region_update (
        region_update_id INTEGER PRIMARY KEY,

        date DATETIME NOT NULL,
        update_type_raw TEXT NOT NULL,
        region_name Text
      );
      """#

    /// SQL to `SELECT` all columns of the `region_update` table.
    public static let select = #"SELECT "region_update_id", "date", "update_type_raw", "region_name" FROM "region_update""#

    /// SQL fragment representing all columns.
    public static let selectColumns = #""region_update_id", "date", "update_type_raw", "region_name""#

    /// Index positions of the properties in ``selectColumns``.
    public static let selectColumnIndices : PropertyIndices = ( 0, 1, 2, 3 )

    /// SQL to `SELECT` all columns of the `region_update` table using a Swift filter.
    public static let matchSelect = #"SELECT "region_update_id", "date", "update_type_raw", "region_name" FROM "region_update" WHERE regionUpdates_swift_match("region_update_id", "date", "update_type_raw", "region_name") != 0"#

    /// SQL to `UPDATE` all columns of the `region_update` table.
    public static let update = #"UPDATE "region_update" SET "date" = ?, "update_type_raw" = ?, "region_name" = ? WHERE "region_update_id" = ?"#

    /// Property parameter indicies in the ``update`` SQL
    public static let updateParameterIndices : PropertyIndices = ( 4, 1, 2, 3 )

    /// SQL to `INSERT` a record into the `region_update` table.
    public static let insert = #"INSERT INTO "region_update" ( "date", "update_type_raw", "region_name" ) VALUES ( ?, ?, ? )"#

    /// SQL to `INSERT` a record into the `region_update` table.
    public static let insertReturning = #"INSERT INTO "region_update" ( "date", "update_type_raw", "region_name" ) VALUES ( ?, ?, ? ) RETURNING "region_update_id", "date", "update_type_raw", "region_name""#

    /// Property parameter indicies in the ``insert`` SQL
    public static let insertParameterIndices : PropertyIndices = ( -1, 1, 2, 3 )

    /// SQL to `DELETE` a record from the `region_update` table.
    public static let delete = #"DELETE FROM "region_update" WHERE "region_update_id" = ?"#

    /// Property parameter indicies in the ``delete`` SQL
    public static let deleteParameterIndices : PropertyIndices = ( 1, -1, -1, -1 )

    /**
     * Lookup property indices by column name in a statement handle.
     *
     * Properties are ordered in the schema and have a specific index
     * assigned.
     * E.g. if the record has two properties, `id` and `name`,
     * and the query was `SELECT age, region_update_id FROM region_update`,
     * this would return `( idx_id: 1, idx_name: -1 )`.
     * Because the `region_update_id` is in the second position and `name`
     * isn't provided at all.
     *
     * - Parameters:
     *   - statement: A raw SQLite3 prepared statement handle.
     * - Returns: The positions of the properties in the prepared statement.
     */
    @inlinable
    public static func lookupColumnIndices(`in` statement: OpaquePointer!)
    -> PropertyIndices
    {
      var indices : PropertyIndices = ( -1, -1, -1, -1 )
      for i in 0..<sqlite3_column_count(statement) {
        let col = sqlite3_column_name(statement, i)
        if strcmp(col!, "region_update_id") == 0 {
          indices.idx_id = i
        }
        else if strcmp(col!, "date") == 0 {
          indices.idx_date = i
        }
        else if strcmp(col!, "update_type_raw") == 0 {
          indices.idx_updateTypeRaw = i
        }
        else if strcmp(col!, "region_name") == 0 {
          indices.idx_regionName = i
        }
      }
      return indices
    }

    /**
     * Register the Swift matcher function for the ``RegionUpdate`` record.
     *
     * SQLite Swift matcher functions are used to process `filter` queries
     * and low-level matching w/o the Lighter library.
     *
     * - Parameters:
     *   - unsafeDatabaseHandle: SQLite3 database handle.
     *   - flags: SQLite3 function registration flags, default: `SQLITE_UTF8`
     *   - matcher: A pointer to the Swift closure used to filter the records.
     * - Returns: The result code of `sqlite3_create_function`, e.g. `SQLITE_OK`.
     */
    @inlinable
    @discardableResult
    public static func registerSwiftMatcher(
      `in` unsafeDatabaseHandle: OpaquePointer!,
      flags: Int32 = SQLITE_UTF8,
      matcher: UnsafeRawPointer
    ) -> Int32
    {
      func dispatch(
        _ context: OpaquePointer?,
        argc: Int32,
        argv: UnsafeMutablePointer<OpaquePointer?>!
      )
      {
        if let closureRawPtr = sqlite3_user_data(context) {
          let closurePtr = closureRawPtr.bindMemory(to: MatchClosureType.self, capacity: 1)
          let indices = RegionUpdate.Schema.selectColumnIndices
          let record = RegionUpdate(
            id: (indices.idx_id >= 0) && (indices.idx_id < argc) ? (sqlite3_value_type(argv[Int(indices.idx_id)]) != SQLITE_NULL ? Int(sqlite3_value_int64(argv[Int(indices.idx_id)])) : nil) : RecordType.schema.id.defaultValue,
            date: ((indices.idx_date >= 0) && (indices.idx_date < argc) && (sqlite3_value_type(argv[Int(indices.idx_date)]) != SQLITE_NULL) ? (sqlite3_value_type(argv[Int(indices.idx_date)]) == SQLITE_TEXT ? (sqlite3_value_text(argv[Int(indices.idx_date)]).flatMap({ BeenOutside.dateFormatter?.date(from: String(cString: $0)) })) : Date(timeIntervalSince1970: sqlite3_value_double(argv[Int(indices.idx_date)]))) : nil) ?? RecordType.schema.date.defaultValue,
            updateTypeRaw: ((indices.idx_updateTypeRaw >= 0) && (indices.idx_updateTypeRaw < argc) ? (sqlite3_value_text(argv[Int(indices.idx_updateTypeRaw)]).flatMap(String.init(cString:))) : nil) ?? RecordType.schema.updateTypeRaw.defaultValue,
            regionName: (indices.idx_regionName >= 0) && (indices.idx_regionName < argc) ? (sqlite3_value_text(argv[Int(indices.idx_regionName)]).flatMap(String.init(cString:))) : RecordType.schema.regionName.defaultValue
          )
          sqlite3_result_int(context, closurePtr.pointee(record) ? 1 : 0)
        }
        else {
          sqlite3_result_error(context, "Missing Swift matcher closure", -1)
        }
      }
      return sqlite3_create_function(
        unsafeDatabaseHandle,
        "regionUpdates_swift_match",
        RegionUpdate.Schema.columnCount,
        flags,
        UnsafeMutableRawPointer(mutating: matcher),
        dispatch,
        nil,
        nil
      )
    }

    /**
     * Unregister the Swift matcher function for the ``RegionUpdate`` record.
     *
     * SQLite Swift matcher functions are used to process `filter` queries
     * and low-level matching w/o the Lighter library.
     *
     * - Parameters:
     *   - unsafeDatabaseHandle: SQLite3 database handle.
     *   - flags: SQLite3 function registration flags, default: `SQLITE_UTF8`
     * - Returns: The result code of `sqlite3_create_function`, e.g. `SQLITE_OK`.
     */
    @inlinable
    @discardableResult
    public static func unregisterSwiftMatcher(
      `in` unsafeDatabaseHandle: OpaquePointer!,
      flags: Int32 = SQLITE_UTF8
    ) -> Int32
    {
      sqlite3_create_function(
        unsafeDatabaseHandle,
        "regionUpdates_swift_match",
        RegionUpdate.Schema.columnCount,
        flags,
        nil,
        nil,
        nil,
        nil
      )
    }

    /// Type information for property ``RegionUpdate/id`` (`region_update_id` column).
    public let id = MappedColumn<RegionUpdate, Int?>(
      externalName: "region_update_id",
      defaultValue: nil,
      keyPath: \RegionUpdate.id
    )

    /// Type information for property ``RegionUpdate/date`` (`date` column).
    public let date = MappedColumn<RegionUpdate, Date>(
      externalName: "date",
      defaultValue: Date(timeIntervalSince1970: 0),
      keyPath: \RegionUpdate.date
    )

    /// Type information for property ``RegionUpdate/updateTypeRaw`` (`update_type_raw` column).
    public let updateTypeRaw = MappedColumn<RegionUpdate, String>(
      externalName: "update_type_raw",
      defaultValue: "",
      keyPath: \RegionUpdate.updateTypeRaw
    )

    /// Type information for property ``RegionUpdate/regionName`` (`region_name` column).
    public let regionName = MappedColumn<RegionUpdate, String?>(
      externalName: "region_name",
      defaultValue: nil,
      keyPath: \RegionUpdate.regionName
    )

#if swift(>=5.7)
    public var _allColumns : [ any SQLColumn ] { [ id, date, updateTypeRaw, regionName ] }
#endif // swift(>=5.7)
  }

  /**
   * Initialize a ``RegionUpdate`` record from a SQLite statement handle.
   *
   * This initializer allows easy setup of a record structure from an
   * otherwise arbitrarily constructed SQLite prepared statement.
   *
   * If no `indices` are specified, the `Schema/lookupColumnIndices`
   * function will be used to find the positions of the structure properties
   * based on their external name.
   * When looping, it is recommended to do the lookup once, and then
   * provide the `indices` to the initializer.
   *
   * Required values that are missing in the statement are replaced with
   * their assigned default values, i.e. this can even be used to perform
   * partial selects w/ only a minor overhead (the extra space for a
   * record).
   *
   * Example:
   * ```swift
   * var statement : OpaquePointer?
   * sqlite3_prepare_v2(dbHandle, "SELECT * FROM region_update", -1, &statement, nil)
   * while sqlite3_step(statement) == SQLITE_ROW {
   *   let record = RegionUpdate(statement)
   *   print("Fetched:", record)
   * }
   * sqlite3_finalize(statement)
   * ```
   *
   * - Parameters:
   *   - statement: Statement handle as returned by `sqlite3_prepare*` functions.
   *   - indices: Property bindings positions, defaults to `nil` (automatic lookup).
   */
  @inlinable
  init(_ statement: OpaquePointer!, indices: Schema.PropertyIndices? = nil)
  {
    let indices = indices ?? Self.Schema.lookupColumnIndices(in: statement)
    let argc = sqlite3_column_count(statement)
    self.init(
      id: (indices.idx_id >= 0) && (indices.idx_id < argc) ? (sqlite3_column_type(statement, indices.idx_id) != SQLITE_NULL ? Int(sqlite3_column_int64(statement, indices.idx_id)) : nil) : Self.schema.id.defaultValue,
      date: ((indices.idx_date >= 0) && (indices.idx_date < argc) && (sqlite3_column_type(statement, indices.idx_date) != SQLITE_NULL) ? (sqlite3_column_type(statement, indices.idx_date) == SQLITE_TEXT ? (sqlite3_column_text(statement, indices.idx_date).flatMap({ BeenOutside.dateFormatter?.date(from: String(cString: $0)) })) : Date(timeIntervalSince1970: sqlite3_column_double(statement, indices.idx_date))) : nil) ?? Self.schema.date.defaultValue,
      updateTypeRaw: ((indices.idx_updateTypeRaw >= 0) && (indices.idx_updateTypeRaw < argc) ? (sqlite3_column_text(statement, indices.idx_updateTypeRaw).flatMap(String.init(cString:))) : nil) ?? Self.schema.updateTypeRaw.defaultValue,
      regionName: (indices.idx_regionName >= 0) && (indices.idx_regionName < argc) ? (sqlite3_column_text(statement, indices.idx_regionName).flatMap(String.init(cString:))) : Self.schema.regionName.defaultValue
    )
  }

  /**
   * Bind all ``RegionUpdate`` properties to a prepared statement and call a closure.
   *
   * *Important*: The bindings are only valid within the closure being executed!
   *
   * Example:
   * ```swift
   * var statement : OpaquePointer?
   * sqlite3_prepare_v2(
   *   dbHandle,
   *   #"UPDATE "region_update" SET "date" = ?, "update_type_raw" = ?, "region_name" = ? WHERE "region_update_id" = ?"#,
   *   -1, &statement, nil
   * )
   *
   * let record = RegionUpdate(id: 1, date: ..., updateTypeRaw: "Hello", regionName: "World")
   * let ok = record.bind(to: statement, indices: ( 4, 1, 2, 3 )) {
   *   sqlite3_step(statement) == SQLITE_DONE
   * }
   * sqlite3_finalize(statement)
   * ```
   *
   * - Parameters:
   *   - statement: A SQLite3 statement handle as returned by the `sqlite3_prepare*` functions.
   *   - indices: The parameter positions for the bindings.
   *   - execute: Closure executed with bindings applied, bindings _only_ valid within the call!
   * - Returns: Returns the result of the closure that is passed in.
   */
  @inlinable
  @discardableResult
  func bind<R>(
    to statement: OpaquePointer!,
    indices: Schema.PropertyIndices,
    then execute: () throws -> R
  ) rethrows -> R
  {
    if indices.idx_id >= 0 {
      if let id = id {
        sqlite3_bind_int64(statement, indices.idx_id, Int64(id))
      }
      else {
        sqlite3_bind_null(statement, indices.idx_id)
      }
    }
    if indices.idx_date >= 0 {
      sqlite3_bind_double(statement, indices.idx_date, date.timeIntervalSince1970)
    }
    return try updateTypeRaw.withCString() { ( s ) in
      if indices.idx_updateTypeRaw >= 0 {
        sqlite3_bind_text(statement, indices.idx_updateTypeRaw, s, -1, nil)
      }
      return try BeenOutside.withOptCString(regionName) { ( s ) in
        if indices.idx_regionName >= 0 {
          sqlite3_bind_text(statement, indices.idx_regionName, s, -1, nil)
        }
        return try execute()
      }
    }
  }
}
