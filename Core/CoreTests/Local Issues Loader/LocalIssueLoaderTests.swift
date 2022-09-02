//
//  Created by Peter Combee on 02/09/2022.
//

import XCTest
import Core

final class LocalIssueLoaderTests: XCTestCase {
    
    func test_loadIssues_deliversErrorOnMapperError() {
        let fileURL = testSpecificFileURL()
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: { data in
            throw anyError()
        })

        try! invalidData().write(to: testSpecificFileURL())
        
        let exp = expectation(description: "wait for load completion")
        var mapperError: Error?
        sut.loadIssues {
            if case let .failure(error) = $0 { mapperError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mapperError as? NSError, anyError())
        
        removeTestFile()
    }

    func test_loadIssues_deliversErrorOnMissingFile() {
        let fileURL = testSpecificFileURL()
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: { data in
            throw anyError()
        })

        removeTestFile()
        
        let exp = expectation(description: "wait for load completion")
        var mapperError: Error?
        sut.loadIssues {
            if case let .failure(error) = $0 { mapperError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual((mapperError as? NSError)?.code, fileNotFoundError().code)
        XCTAssertEqual((mapperError as? NSError)?.domain, fileNotFoundError().domain)
    }

    func test_loadIssues_deliversIssuesOnSuccessfulMapping() {
        let fileURL = testSpecificFileURL()
        let issues = sampleIssues()
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: { data in
            return issues
        })
        
        try! Data("any".utf8).write(to: testSpecificFileURL())

        let exp = expectation(description: "wait for load completion")
        var receivedIssues: [Issue]?
        sut.loadIssues {
            if case let .success(issues) = $0 { receivedIssues = issues }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedIssues, issues)
        
        removeTestFile()
    }
    
    // MARK: Helpers
    
    private func testSpecificFileURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
    }
    
    private func sampleIssues() -> [Issue] {
        [
            Issue(firstName: "Theo", surname: "Jansen", amountOfIssues: 5, birthDate: Date(timeIntervalSince1970: 252543600)),
            Issue(firstName: "Fiona", surname: "de Vries", amountOfIssues: 7, birthDate: Date(timeIntervalSince1970: -603939600)),
            Issue(firstName: "Petra", surname: "Boersma", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 987717600)),
        ]
    }
    
    private func invalidData() -> Data {
        Data(capacity: 1)
    }
    
    private func fileNotFoundError() -> NSError {
        NSError(domain: "NSCocoaErrorDomain", code: 260)
    }
    
    private func removeTestFile() {
        try? FileManager.default.removeItem(at: testSpecificFileURL())
    }
}

// MARK: Helpers

private func anyError() -> NSError {
    NSError(domain: "any", code: 1)
}
