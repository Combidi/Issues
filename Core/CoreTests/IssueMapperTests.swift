//
//  Created by Peter Combee on 30/08/2022.
//

import XCTest
import Core

final class IssueMapper {
    
    private enum Error: Swift.Error {
        case invalidData
    }
    
    static func map(file: Data) throws -> [Issue] {
        throw Error.invalidData
    }
}

final class CSVIssueParserTests: XCTestCase {
    
    func test_deliversErrorOnInvalidData() {
        let invalidData = Data("invalid data".utf8)
        
        XCTAssertThrowsError(try IssueMapper.map(file: invalidData), "Expected an error on invalid data format")
    }
}
