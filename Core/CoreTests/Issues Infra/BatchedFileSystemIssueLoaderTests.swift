//
//  Created by Peter Combee on 02/03/2023.
//

import XCTest
import Core

final class StreamingReaderStub: StreamingReader {
    private var stub: [String]?
    
    init(stub: [String]?) {
        self.stub = stub?.reversed()
    }
        
    func nextLine() -> String? {
        return stub?.popLast()
    }
}

protocol StreamingReader {
    func nextLine() -> String?
}

final class BatchedFileSystemIssueLoader: IssuesLoader {
    typealias Mapper = (String) throws -> Issue
    
    private let streamingReader: StreamingReader
    private let batchSize: Int
    private let mapper: Mapper
    
    init(streamingReader: StreamingReader, batchSize: Int, mapper: @escaping Mapper) {
        self.streamingReader = streamingReader
        self.batchSize = batchSize
        self.mapper = mapper
    }
    
    func loadIssues(completion: @escaping Completion) {
        var issues = [Issue]()
        for _ in 0..<batchSize {
            guard let nextLine = streamingReader.nextLine() else {
                return completion(.success(issues))
            }
            do {
                let issue = try mapper(nextLine)
                issues.append(issue)
            } catch {
                return completion(.failure(error))
            }
        }
        completion(.success(issues))
    }
}

class BatchedFileSystemIssueLoaderTests: XCTestCase {
         
    func test_loadIssues_deliversErrorOnMappingError() {
        let mapperError = NSError(domain: "any", code: 1)
        let sut = makeSUT(
            readerStub: ["invalid data"],
            mapper: { line in throw mapperError }
        )

        assertThat(sut, completesWith: .failure(mapperError))
    }
        
    func test_loadIssues_deliversFiniteMappedIssues() {
        let sut = makeSUT(
            readerStub: ["Peter", "Henk"],
            mapper: makeIssue
        )

        let expectedIssues = [
            makeIssue(firstname: "Peter"),
            makeIssue(firstname: "Henk")
        ]

        assertThat(sut, completesWith: .success(expectedIssues))
    }
    
    func test_loadIssues_doesNotDeliverMoreThanFixedAmountOfIssues() {
        let sut = makeSUT(
            batchSize: 3,
            readerStub: ["Peter", "Henk", "Kees", "Klaas"],
            mapper: makeIssue
        )

        let expectedIssues = [
            makeIssue(firstname: "Peter"),
            makeIssue(firstname: "Henk"),
            makeIssue(firstname: "Kees")
        ]

        assertThat(sut, completesWith: .success(expectedIssues))
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        batchSize: Int = 5,
        readerStub: [String] = [],
        mapper: @escaping BatchedFileSystemIssueLoader.Mapper = { _ in anyIssue() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BatchedFileSystemIssueLoader {
        let streamingReader = StreamingReaderStub(stub: readerStub)
        let sut = BatchedFileSystemIssueLoader(
            streamingReader: streamingReader,
            batchSize: batchSize,
            mapper: mapper
        )
        
        trackForMemoryLeaks(streamingReader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return sut
    }
    
    private func assertThat(
        _ sut: BatchedFileSystemIssueLoader,
        completesWith expectedResult: Result<[Issue], Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var receivedResult: Result<[Issue], Error>?
        let exp = expectation(description: "wait for load completion")
        sut.loadIssues {
            receivedResult = $0
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        
        switch (receivedResult, expectedResult) {
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            
        case let (.success(receivedIssues), .success(expectedIssues)):
            XCTAssertEqual(receivedIssues, expectedIssues, file: file, line: line)
            
        default:
            XCTFail("Expected \(expectedResult), got \(String(describing: receivedResult)) instead", file: file, line: line)

        }
    }
}

private let fixedDate = Date()

private func makeIssue(firstname: String) -> Issue {
    Issue(firstName: firstname, surname: "surname", submissionDate: fixedDate, subject: "subject")
}

private func anyIssue() -> Issue {
    Issue(firstName: "any", surname: "any", submissionDate: .init(), subject: "any")
}
