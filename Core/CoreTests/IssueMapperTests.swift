//
//  Created by Peter Combee on 30/08/2022.
//

import XCTest
import Core

final class IssueMapper {
    
    private enum Error: Swift.Error {
        case invalidHeaders
    }
    
    static func map(_ data: Data) throws -> [Issue] {
        throw Error.invalidHeaders
    }
}

final class CSVIssueParserTests: XCTestCase {
    
    func test_map_deliversErrorOnInvalidHeaders() {
        let dataWithInvalidHeaders = Data("""
            "first col header", "second col header", "third col header", "fourth col header",
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            """.utf8
        )
        
        
        XCTAssertThrowsError(try IssueMapper.map(dataWithInvalidHeaders), "Expected an error on invalid headers")
    }
}
