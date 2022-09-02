//
//  Created by Peter Combee on 01/09/2022.
//

import XCTest
import Core

final class LoadIssuesFromLocalCSVFileTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyState()
    }
    
    override func tearDown() {
        super.tearDown()

        undoSideEffects()
    }

    func test_loadIssue_deliversIssuesOnSuccessMapping() {
        let sut = makeSUT()
        
        try! sampleIssues().data.write(to: testSpecificFileURL())

        let expectation = expectation(description: "wait for load completion")
        var receivedIssues: [Issue]?
        sut.loadIssues { result in
            if case let .success(issues) = result {
                receivedIssues = issues
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedIssues, sampleIssues().issues)
    }

    func test_loadIssue_deliversErrorOnMissingFile() {
        let sut = makeSUT()
        
        let expectation = expectation(description: "wait for load completion")
        var loadError: Error?
        sut.loadIssues { result in
            if case let .failure(error) = result {
                loadError = error
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(loadError, "Expected load to fail")
    }

    func test_loadIssue_deliversErrorOnMappingError() {
        let sut = makeSUT()
        
        try! invalidData().write(to: testSpecificFileURL())

        let expectation = expectation(description: "wait for load completion")
        var mapperError: Error?
        sut.loadIssues { result in
            if case let .failure(error) = result {
                mapperError = error
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(mapperError, "Expected load to fail")
    }
    
    // MARK: Helpers
    
    private func makeSUT() -> LocalIssueLoader {
        let timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        let fileURL = testSpecificFileURL()
        let csvMapper = { data in
            try CSVIssuesMapper.map(data, timeZone: timeZone)
        }
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: csvMapper)
        return sut
    }
    
    private func testSpecificFileURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
    }
    
    private func sampleIssues() -> (data: Data, issues: [Issue]) {
        let issuesData = Data(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            "Fiona","de Vries",7,"1950-11-12T00:00:00"
            "Petra","Boersma",1,"2001-04-20T00:00:00"
            """.utf8
        )
        let issues = [
            Issue(firstName: "Theo", surname: "Jansen", amountOfIssues: 5, birthDate: Date(timeIntervalSince1970: 252543600)),
            Issue(firstName: "Fiona", surname: "de Vries", amountOfIssues: 7, birthDate: Date(timeIntervalSince1970: -603939600)),
            Issue(firstName: "Petra", surname: "Boersma", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 987717600)),
        ]
        return (issuesData, issues)
    }
    
    private func invalidData() -> Data {
        Data(capacity: 1)
    }
        
    private func setupEmptyState() {
        deleteTestSpecificFile()
    }
    
    private func undoSideEffects() {
        deleteTestSpecificFile()
    }

    private func deleteTestSpecificFile() {
        try? FileManager.default.removeItem(at: testSpecificFileURL())
    }
}
