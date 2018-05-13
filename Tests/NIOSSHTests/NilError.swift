
import XCTest

func requireNotNil<T>(_ optional: T?, name: String, file: StaticString = #file, line: UInt = #line) throws -> T {
    XCTAssertNotNil(optional, errorMessage(for: name), file: file, line: line)

    if let element = optional {
        return element
    } else {
        throw NilError(name)
    }
}

struct NilError: Error {
    let message: String

    init(_ name: String) {
        message = errorMessage(for: name)
    }
}

private func errorMessage(for name: String) -> String {
    return "\(name) is nil"
}
