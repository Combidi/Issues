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
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            """.utf8
        )
        
        assertThat(try CSVIssuesMapper.map(dataWithInvalidHeaders), throws: .invalidHeaders)
    }
    
    func test_map_deliversEmptyIssuesOnValidHeaderWithEmptyData() {
        let dataWithEmptyIssues = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            """.utf8
        )
                
        XCTAssertTrue(try CSVIssuesMapper.map(dataWithEmptyIssues).isEmpty, "Expected empty issues")
    }

    func test_map_throwsOnInvalidColumnSize() {
        let dataWithInvalidColumsSize = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            "Fiona","de Vries",7
            """.utf8
        )

        assertThat(try CSVIssuesMapper.map(dataWithInvalidColumsSize), throws: .invalidColumnSize(columnIndex: 1))
    }
    
    func test_map_throwsOnNonIntConvertibleIssueCount() {
        let dataWithInvalidColumsSize = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen","non Int convertible value","1978-01-02T00:00:00"
            """.utf8
        )

        assertThat(try CSVIssuesMapper.map(dataWithInvalidColumsSize), throws: .nonIntConvertable(columnIndex: 0, elementIndex: 2))
    }

    func test_map_validIssueDataDeliversIssues() {
        let validDataWithIssues = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            "Fiona","de Vries",7,"1950-11-12T00:00:00"
            "Petra","Boersma",1,"2001-04-20T00:00:00"
            """.utf8
        )
        
        let expectedIssues = [
            Issue(firstName: "Theo", surname: "Jansen", amountOfIssues: 5, birthDate: Date(timeIntervalSince1970: 252540000)),
            Issue(firstName: "Fiona", surname: "de Vries", amountOfIssues: 7, birthDate: Date(timeIntervalSince1970: -603943200)),
            Issue(firstName: "Petra", surname: "Boersma", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 987714000)),
        ]

        let timeZone = TimeZone(identifier: "Asia/Amman")!
        XCTAssertEqual(try CSVIssuesMapper.map(validDataWithIssues, timeZone: timeZone), expectedIssues)
    }
    func test_map_throwsOnIncorrectBirthDateFormat() {
        let dateWithInvalidDateFormat = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Petra","Boersma",1,"2001-04-20T00:00:00"
            "Theo","Jansen",5,"2020-08-28T15:07:02+00:00"
            """.utf8
        )

        assertThat(try CSVIssuesMapper.map(dateWithInvalidDateFormat), throws: .invalidDateFormat(columnIndex: 1, elementIndex: 3))
    }
    
    func test_map_supportsCarriageReturn() {
        let dataWithCarriageReturnNewLineCharacters = Data("\"First name\",\"Sur name\",\"Issue count\",\"Date of birth\"\r \"Petra\",\"Boersma\",1,\"2001-04-20T00:00:00\"".utf8
        )
        
        XCTAssertNoThrow(try CSVIssuesMapper.map(dataWithCarriageReturnNewLineCharacters))
    }
    
    func test_map_supportsLineFeed() {
        let dataWithCarriageReturnNewLineCharacters = Data("\"First name\",\"Sur name\",\"Issue count\",\"Date of birth\"\n \"Petra\",\"Boersma\",1,\"2001-04-20T00:00:00\"".utf8
        )
        
        XCTAssertNoThrow(try CSVIssuesMapper.map(dataWithCarriageReturnNewLineCharacters))
    }
    
    func test_map_supportsCarriageReturnLineFeed() {
        let dataWithCarriageReturnLineFeedNewLineCharacters = Data("\"First name\",\"Sur name\",\"Issue count\",\"Date of birth\"\r\n \"Petra\",\"Boersma\",1,\"2001-04-20T00:00:00\"".utf8
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
