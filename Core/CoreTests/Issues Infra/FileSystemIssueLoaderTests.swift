//
//  Created by Peter Combee on 02/09/2022.
//

import XCTest
import Core

final class FileSystemIssueLoaderTests: XCTestCase {
        
    func test_loadIssues_deliversErrorOnMapperError() {
        let mapperError = anyError()
        let sut = makeSUT(mapper: { _ in throw mapperError })
        saveTestFileWith(data: invalidData())
        
        assertThat(sut, completesWith: mapperError)
    }
    
    func test_loadIssues_deliversErrorOnMissingFile() {
        let sut = makeSUT()
        removeTestFile()
        
        assertThat(sut, completesWith: fileNotFoundError())
    }
    
    func test_loadIssues_deliversIssuesOnSuccessfullMapping() {
        let issues = [sampleIssue()]
        let validData = validData()
        let sut = makeSUT(mapper: { data in
            XCTAssertEqual(data, validData, "wrong data passed to mapper")
            return issues
        })
        saveTestFileWith(data: validData)

        assertThat(sut, completesWith: issues)
    }
    
    // MARK: Helpers
    
    private func makeSUT(mapper: @escaping (Data) throws -> [Issue] = { _ in [] }) -> FileSystemIssueLoader {
        let fileURL = testSpecificFileURL()
        let sut = FileSystemIssueLoader(fileURL: fileURL, mapper: mapper)
        return sut
    }

    private func assertThat(
        _ sut: FileSystemIssueLoader,
        completesWith expectedError: NSError,
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
        _ sut: FileSystemIssueLoader,
        completesWith expectedIssues: [Issue],
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
        using sut: FileSystemIssueLoader,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> IssuesLoader.LoadIssuesResult? {
        let exp = expectation(description: "wait for load completion")
        var receivedResult: IssuesLoader.LoadIssuesResult?
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
    
    private func sampleIssue() -> Issue {
        Issue(firstName: "Theo", surname: "Jansen", submissionDate: Date(timeIntervalSince1970: 252543600), subject: "My television is broken")
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
