//
//  Created by Peter Combee on 01/09/2022.
//

import XCTest
import Core

final class LocalIssueLoader: IssuesLoader {
    private let fileURL: URL
    private let mapper: (Data) throws -> [Issue]
    
    init(fileURL: URL, mapper: @escaping (Data) throws -> [Issue]) {
        self.fileURL = fileURL
        self.mapper = mapper
    }
    
    func loadIssues(completion: @escaping Completion) {
        do {
            let data = try Data(contentsOf: fileURL)
            completion(.success(try! mapper(data)))
        } catch {
            completion(.failure(error))
        }
    }
}

final class LoadIssuesFromLocalCSVFileTests: XCTestCase {
    
    func test_loadIssue_deliversIssuesOnSuccessMapping() {
        let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
        let timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        let csvMapper = { data in
            try CSVIssuesMapper.map(data, timeZone: timeZone)
        }
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: csvMapper)
        
        try! sampleIssues().data.write(to: fileURL)

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
        
        try? FileManager.default.removeItem(at: fileURL)
    }

    func test_loadIssue_deliversErrorOnMissingFile() {
        let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
        let timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        let csvMapper = { data in
            try CSVIssuesMapper.map(data, timeZone: timeZone)
        }
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: csvMapper)
        
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
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: Helpers
    
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
}
