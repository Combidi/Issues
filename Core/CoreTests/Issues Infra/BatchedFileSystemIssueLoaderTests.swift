//
//  Created by Peter Combee on 02/03/2023.
//

import XCTest
import Core

final class StreamingReader {
    private var stub: [String]?
    
    init(stub: [String]?) {
        self.stub = stub?.reversed()
    }
    
    private(set) var nextLineCallCount = 0
    
    func nextLine() -> String? {
        nextLineCallCount += 1
        return stub?.popLast()
    }
}
final class BatchedFileSystemIssueLoader {
    typealias Mapper = (String) throws -> Issue
    
    private let streamingReader: StreamingReader
    private let mapper: Mapper
    
    init(streamingReader: StreamingReader, mapper: @escaping Mapper) {
        self.streamingReader = streamingReader
        self.mapper = mapper
    }
    
    func loadIssues(completion: (Result<[Issue], Error>) -> Void) {
        var issues = [Issue]()
        for _ in 0..<5 {
            guard let nextLine = streamingReader.nextLine() else {
                return completion(.success(issues))
            }
            do {
                let issue = try mapper(nextLine)
                issues.append(issue)
            } catch {
                completion(.failure(error))
            }
        }
        completion(.success(issues))
    }
}

class BatchedFileSystemIssueLoaderTests: XCTestCase {
     
    func test_doesNotRequestLinesOnInit() {
        let (_, streamingReader) = makeSUT()
        
        XCTAssertEqual(streamingReader.nextLineCallCount, 0)
    }
    
    func test_loadIssues_requestsNextLine() {
        let (sut, streamingReader) = makeSUT()

        sut.loadIssues { _ in }
        
        XCTAssertEqual(streamingReader.nextLineCallCount, 1)
    }
    
    func test_loadIssues_deliversErrorOnMappingError() {
        let mapperError = NSError(domain: "any", code: 1)
        let (sut, _) = makeSUT(
            readerStub: ["invalid data"],
            mapper: { line in throw mapperError }
        )

        var receivedError: Error?
        sut.loadIssues { result in
            if case let .failure(error) = result {
                receivedError = error
            }
        }
        
        XCTAssertEqual(receivedError as? NSError, mapperError)
    }
    
    func test_loadIssues_deliversFiniteMappedIssues() {
        let fixedDate = Date()
        let (sut, _) = makeSUT(
            readerStub: ["first", "second"],
            mapper: {
                Issue(firstName: $0, surname: "", submissionDate: fixedDate, subject: "")
            }
        )

        var receivedIssues: [Issue]?
        sut.loadIssues { result in
            if case let .success(issues) = result {
                receivedIssues = issues
            }
        }

        let expectedIssues = [
            Issue(firstName: "first", surname: "", submissionDate: fixedDate, subject: ""),
            Issue(firstName: "second", surname: "", submissionDate: fixedDate, subject: "")
        ]
        XCTAssertEqual(receivedIssues?.count, expectedIssues.count)
        XCTAssertEqual(receivedIssues, expectedIssues)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        readerStub: [String] = [],
        mapper: @escaping BatchedFileSystemIssueLoader.Mapper = { _ in anyIssue() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (BatchedFileSystemIssueLoader, StreamingReader) {
        let streamingReader = StreamingReader(stub: readerStub)
        let sut = BatchedFileSystemIssueLoader(streamingReader: streamingReader, mapper: mapper)
        
        trackForMemoryLeaks(streamingReader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, streamingReader)
    }
}

private func anyIssue() -> Issue {
    Issue(firstName: "any", surname: "any", submissionDate: .init(), subject: "any")
}
