//
//  Created by Peter Combee on 30/08/2022.
//

import XCTest
import Core

final class IssueMapper {

    enum Error: Swift.Error {
        case invalidHeaders
        case invalidColumnSize
        case nonIntConvertable
        case invalidDateFormat
    }
    
    static func map(_ data: Data) throws -> [Issue] {
        
        guard let dataString = String(data: data, encoding: .utf8) else { return [] }
        let stripped = dataString.replacingOccurrences(of: "\"", with: "")
        let lines = stripped.split(separator: "\n")
        var colums = lines.map { $0.split(separator: ",").map(String.init) }
        
        guard colums.removeFirst() == ["First name", "Sur name", "Issue count", "Date of birth"] else {
            throw Error.invalidHeaders
        }
                
        guard colums.allSatisfy({ $0.count == 4 }) else {
            throw Error.invalidColumnSize
        }
        
        let issues: [Issue] = try colums.map { column in
            guard let amountOfIssues = Int(column[2]) else { throw Error.nonIntConvertable }
                        
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            guard let birthDate = formatter.date(from: column[3]) else {
                throw Error.invalidDateFormat
            }
            
            return Issue(firstName: column[0], surname: column[1], amountOfIssues: amountOfIssues, birthDate: birthDate)
        }

        return issues
    }
}

final class CSVIssueParserTests: XCTestCase {
    
    func test_map_throwsOnInvalidHeaders() {
        let dataWithInvalidHeaders = Data(
            """
            "first col header", "second col header", "third col header", "fourth col header",
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            """.utf8
        )
        
        assertThat(try IssueMapper.map(dataWithInvalidHeaders), throws: IssueMapper.Error.invalidHeaders)
    }
    
    func test_map_deliversEmptyIssuesOnValidHeaderWithEmptyData() {
        let dataWithEmptyIssues = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            """.utf8
        )
                
        XCTAssertTrue(try IssueMapper.map(dataWithEmptyIssues).isEmpty, "Expected empty issues")
    }

    func test_map_throwsOnInvalidColumnSize() {
        let dataWithInvalidColumsSize = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5
            """.utf8
        )

        assertThat(try IssueMapper.map(dataWithInvalidColumsSize), throws: IssueMapper.Error.invalidColumnSize)
    }
    
    func test_map_throwsOnNonIntConvertibleIssueCount() {
        let dataWithInvalidColumsSize = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen","non Int convertible value","1978-01-02T00:00:00"
            """.utf8
        )

        assertThat(try IssueMapper.map(dataWithInvalidColumsSize), throws: IssueMapper.Error.nonIntConvertable)
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
            Issue(firstName: "Theo", surname: "Jansen", amountOfIssues: 5, birthDate: Date(timeIntervalSince1970: 252543600)),
            Issue(firstName: "Fiona", surname: "de Vries", amountOfIssues: 7, birthDate: Date(timeIntervalSince1970: -603939600)),
            Issue(firstName: "Petra", surname: "Boersma", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 987717600)),
        ]

        XCTAssertEqual(try IssueMapper.map(validDataWithIssues), expectedIssues)
    }

    func test_map_throwsOnIncorrectBirthDateFormat() {
        let dateWithInvalidDateFormat = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5,"2020-08-28T15:07:02+00:00"
            """.utf8
        )

        assertThat(try IssueMapper.map(dateWithInvalidDateFormat), throws: IssueMapper.Error.invalidDateFormat)
    }

    
    // MARK: Helpers
    
    private func assertThat<T, E: Error & Equatable>(
        _ expression: @autoclosure () throws -> T,
        throws error: E,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?

        XCTAssertThrowsError(try expression(),
                             file: file, line: line) {
            thrownError = $0
        }

        XCTAssertTrue(
            thrownError is E,
            "Unexpected error type: \(type(of: thrownError))",
            file: file, line: line
        )

        XCTAssertEqual(
            thrownError as? E, error,
            file: file, line: line
        )
    }
}
