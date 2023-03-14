//
//  Created by Peter Combee on 30/08/2022.
//

import XCTest
import Core

final class CSVIssuesMapperTests: XCTestCase {
    
    func test_map_throwsOnInvalidData() {
        let invalidData = Data(capacity: 1)
        
        assertThat(try CSVIssuesMapper.map(invalidData), throws: .invalidData)
    }
    
    func test_map_throwsOnInvalidHeaders() {
        let dataWithInvalidHeaders = Data(
            """
            "first col header", "second col header", "third col header", "fourth col header",
            "Theo","Jansen","My television is broken","1978-01-02T00:00:00"
            """.utf8
        )
        
        assertThat(try CSVIssuesMapper.map(dataWithInvalidHeaders), throws: .invalidHeaders)
    }
    
    func test_map_deliversEmptyIssuesOnValidHeaderWithEmptyData() {
        let dataWithEmptyIssues = Data(
            """
            "First name","Sur name","Subject","Date of submission"
            """.utf8
        )
                
        XCTAssertTrue(try CSVIssuesMapper.map(dataWithEmptyIssues).isEmpty, "Expected empty issues")
    }

    func test_map_throwsOnInvalidLineComponentCount() {
        let dataWithInvalidLineComponentCount = Data(
            """
            "First name","Sur name","Subject","Date of submission"
            "Theo","Jansen","My television is broken","1978-01-02T00:00:00"
            "Fiona","de Vries","Can't find my shoes"
            """.utf8
        )

        assertThat(try CSVIssuesMapper.map(dataWithInvalidLineComponentCount), throws: .invalidComponentCount(components: ["Fiona", "de Vries", "Can't find my shoes"]))
    }

    func test_map_validIssueDataDeliversIssues() {
        let validDataWithIssues = Data(
            """
            "First name","Sur name","Subject","Date of submission"
            "Theo","Jansen","My television is broken","1978-01-02T00:00:00"
            "Fiona","de Vries","Can't find my shoes","1950-11-12T00:00:00"
            "Petra","Boersma","Dropped my phone","2001-04-20T00:00:00"
            """.utf8
        )
        
        let expectedIssues = [
            Issue(firstName: "Theo", surname: "Jansen", submissionDate: Date(timeIntervalSince1970: 252540000), subject: "My television is broken"),
            Issue(firstName: "Fiona", surname: "de Vries", submissionDate: Date(timeIntervalSince1970: -603943200), subject: "Can't find my shoes"),
            Issue(firstName: "Petra", surname: "Boersma", submissionDate: Date(timeIntervalSince1970: 987714000), subject: "Dropped my phone"),
        ]

        let timeZone = TimeZone(identifier: "Asia/Amman")!
        XCTAssertEqual(try CSVIssuesMapper.map(validDataWithIssues, timeZone: timeZone), expectedIssues)
    }
    func test_map_throwsOnIncorrectDateFormat() {
        let dateWithInvalidDateFormat = Data(
            """
            "First name","Sur name","Subject","Date of submission"
            "Petra","Boersma","Dropped my phone","2001-04-20T00:00:00"
            "Theo","Jansen",My television is broken,"2020-08-28T15:07:02+00:00"
            """.utf8
        )

        assertThat(try CSVIssuesMapper.map(dateWithInvalidDateFormat), throws: .invalidDateFormat(date: "2020-08-28T15:07:02+00:00"))
    }
    
    func test_map_supportsCarriageReturn() {
        let dataWithCarriageReturnNewLineCharacters = Data("\"First name\",\"Sur name\",\"Subject\",\"Date of submission\"\r \"Petra\",\"Boersma\",\"Dropped my phone\",\"2001-04-20T00:00:00\"".utf8
        )
        
        XCTAssertNoThrow(try CSVIssuesMapper.map(dataWithCarriageReturnNewLineCharacters))
    }
    
    func test_map_supportsLineFeed() {
        let dataWithCarriageReturnNewLineCharacters = Data("\"First name\",\"Sur name\",\"Subject\",\"Date of submission\"\n \"Petra\",\"Boersma\",\"Dropped my phone\",\"2001-04-20T00:00:00\"".utf8
        )
        
        XCTAssertNoThrow(try CSVIssuesMapper.map(dataWithCarriageReturnNewLineCharacters))
    }
    
    func test_map_supportsCarriageReturnLineFeed() {
        let dataWithCarriageReturnLineFeedNewLineCharacters = Data("\"First name\",\"Sur name\",\"Subject\",\"Date of submission\"\r\n \"Petra\",\"Boersma\",\"Dropped my phone\",\"2001-04-20T00:00:00\"".utf8
        )
        
        XCTAssertNoThrow(try CSVIssuesMapper.map(dataWithCarriageReturnLineFeedNewLineCharacters))
    }
    
    // MARK: Helpers
    
    private func assertThat<T>(
        _ expression: @autoclosure () throws -> T,
        throws error: CSVIssuesMapper.Error,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?
        XCTAssertThrowsError(try expression(), file: file, line: line) { thrownError = $0 }
        XCTAssertTrue(thrownError is CSVIssuesMapper.Error, "Unexpected error type: \(type(of: thrownError))", file: file, line: line)
        XCTAssertEqual(thrownError as? CSVIssuesMapper.Error, error, file: file, line: line)
    }
}
