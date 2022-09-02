//
//  Created by Peter Combee on 02/09/2022.
//

import XCTest
import Core

final class LocalIssueLoaderTests: XCTestCase {
    
    func test_loadIssues_deliversErrorOnMapperError() {
        let mapperError = anyError()
        let sut = makeSUT(mapResultStub: .failure(mapperError))
        saveTestFileWith(data: invalidData())
        
        let exp = expectation(description: "wait for load completion")
        var receivedError: Error?
        sut.loadIssues {
            if case let .failure(error) = $0 { receivedError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as? NSError, mapperError)
        
        removeTestFile()
    }

    func test_loadIssues_deliversErrorOnMissingFile() {
        let sut = makeSUT()
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
        let issues = sampleIssues()
        let sut = makeSUT(mapResultStub: .success(issues))
        saveTestFileWith(data: validData())

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
    
    private func makeSUT(mapResultStub resultStub: Result<[Issue], NSError> = .success([])) -> LocalIssueLoader {
        let fileURL = testSpecificFileURL()
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: { data in
            switch resultStub {
            case .failure(let error):
                throw error
                
            case .success(let issues):
                return issues
                
            }
        })
        return sut
    }

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
    
    private func validData() -> Data {
        Data("any".utf8)
    }
    
    private func fileNotFoundError() -> NSError {
        NSError(domain: "NSCocoaErrorDomain", code: 260)
    }
    
    private func saveTestFileWith(data: Data) {
        try! data.write(to: testSpecificFileURL())
    }
    
    private func removeTestFile() {
        try? FileManager.default.removeItem(at: testSpecificFileURL())
    }
}

// MARK: Helpers

private func anyError() -> NSError {
    NSError(domain: "any", code: 1)
}
