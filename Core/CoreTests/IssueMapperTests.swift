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
        
        guard let dataString = String(data: data, encoding: .utf8) else { return [] }
        let stripped = dataString.replacingOccurrences(of: "\"", with: "")
        let lines = stripped.split(separator: "\n")
        var colums = lines.map { $0.split(separator: ",").map(String.init) }
        
        guard colums.removeFirst() == ["First name", "Sur name", "Issue count", "Date of birth"] else {
            throw Error.invalidHeaders
        }
        
        return []
        
    }
}

final class CSVIssueParserTests: XCTestCase {
    
    func test_map_deliversErrorOnInvalidHeaders() {
        let dataWithInvalidHeaders = Data(
            """
            "first col header", "second col header", "third col header", "fourth col header",
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            """.utf8
        )
        
        XCTAssertThrowsError(try IssueMapper.map(dataWithInvalidHeaders), "Expected an error on invalid headers")
    }
    
    func test_map_deliversEmptyIssuesOnValidHeaderWithEmptyData() {
        let dataWithEmptyIssues = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            """.utf8
        )
                
        XCTAssertTrue(try IssueMapper.map(dataWithEmptyIssues).isEmpty, "Expected empty issues")
    }
}
