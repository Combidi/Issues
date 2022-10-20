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
        
        assertThat(sut, completesWithError: mapperError)
    }

    func test_loadIssues_deliversErrorOnMissingFile() {
        let sut = makeSUT()
        removeTestFile()
        
        assertThat(sut, completesWithError: fileNotFoundError())
    }
    
    func test_loadIssues_deliversIssuesOnSuccessfulMapping() {
        let issues = sampleIssues()
        let sut = makeSUT(mapResultStub: .success(issues))
        saveTestFileWith(data: validData())

        assertThat(sut, completesWithIssues: issues)
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

    private func assertThat(
        _ sut: LocalIssueLoader,
        completesWithError expectedError: NSError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch loadIssues(using: sut, file: file, line: line) {
        case .none:
            XCTFail("Expected load to complete", file: file, line: line)
            
        case let .failure(receivedError as NSError):
            XCTAssertTrue(
                receivedError.code == expectedError.code,
                "Expected error with code \(expectedError.code), got \(receivedError.code) instead",
                file: file, line: line
            )
            XCTAssertTrue(
                receivedError.domain == expectedError.domain,
                "Expected error with domain `\(expectedError.domain)`, got `\(receivedError.domain)` instead",
                file: file, line: line
            )
        
        case let .some(receivedResult):
            XCTFail("Expected load to complete with error \(expectedError), got \(receivedResult) instead", file: file, line: line)
        
        }

        removeTestFile()
    }
    
    private func assertThat(
        _ sut: LocalIssueLoader,
        completesWithIssues expectedIssues: [Issue],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch loadIssues(using: sut, file: file, line: line) {
        case .none:
            XCTFail("Expected load to complete", file: file, line: line)
            
        case let .success(receivedIssues):
            XCTAssertTrue(receivedIssues == expectedIssues, "Expected load to complete with \(expectedIssues), got \(receivedIssues) instead", file: file, line: line)

        case let .some(receivedResult):
            XCTFail("Expected load to complete with error \(expectedIssues), got \(receivedResult) instead", file: file, line: line)
        }
        
        removeTestFile()
    }
    
    private func loadIssues(
        using sut: LocalIssueLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> IssuesLoader.Result? {
        let exp = expectation(description: "wait for load completion")
        var receivedResult: IssuesLoader.Result?
        sut.loadIssues {
            receivedResult = $0
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.1)
        
        return receivedResult
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
    
    private func anyError() -> NSError {
        NSError(domain: "any", code: 1)
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