import Foundation
import SQLite3

public enum SQLiteError: Error, Sendable, Equatable {
    case open(String)
    case statement(String)
}

/// Minimal typed wrapper over the system SQLite library. Not thread-safe: owned by one actor.
final class SQLiteDatabase {
    private var handle: OpaquePointer?
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// `nil` URL opens an in-memory database (tests).
    init(url: URL?) throws {
        let path = url?.path ?? ":memory:"
        guard sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            throw SQLiteError.open(String(cString: sqlite3_errmsg(handle)))
        }
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA synchronous = NORMAL")
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    func execute(_ sql: String) throws {
        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw error() }
    }

    /// Runs `sql` once per row of `bindings` inside a transaction.
    func run(_ sql: String, rows: [[SQLiteValue]]) throws {
        try execute("BEGIN")
        do {
            let statement = try prepare(sql)
            defer { sqlite3_finalize(statement) }
            for row in rows {
                try bind(row, to: statement)
                guard sqlite3_step(statement) == SQLITE_DONE else { throw error() }
                sqlite3_reset(statement)
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    func query(_ sql: String, _ bindings: [SQLiteValue] = []) throws -> [[SQLiteValue]] {
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var rows: [[SQLiteValue]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append((0..<sqlite3_column_count(statement)).map { column(statement, $0) })
        }
        return rows
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        return statement
    }

    private func bind(_ values: [SQLiteValue], to statement: OpaquePointer?) throws {
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            let result: Int32 = switch value {
            case let .integer(number): sqlite3_bind_int64(statement, position, number)
            case let .real(number): sqlite3_bind_double(statement, position, number)
            case let .text(string): sqlite3_bind_text(statement, position, string, -1, Self.transient)
            case .null: sqlite3_bind_null(statement, position)
            }
            guard result == SQLITE_OK else { throw error() }
        }
    }

    private func column(_ statement: OpaquePointer?, _ index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER: .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT: .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT: .text(String(cString: sqlite3_column_text(statement, index)))
        default: .null
        }
    }

    private func error() -> SQLiteError {
        .statement(String(cString: sqlite3_errmsg(handle)))
    }
}

enum SQLiteValue: Equatable {
    case integer(Int64)
    case real(Double)
    case text(String)
    case null

    var double: Double? {
        switch self {
        case let .real(value): value
        case let .integer(value): Double(value)
        default: nil
        }
    }

    var int64: Int64? {
        if case let .integer(value) = self { return value }
        return nil
    }

    var string: String? {
        if case let .text(value) = self { return value }
        return nil
    }
}
