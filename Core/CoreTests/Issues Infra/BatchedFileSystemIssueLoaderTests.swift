//
//  Created by Peter Combee on 02/03/2023.
//

import XCTest
import Core

final class StreamingReader {
    init(stub: [String]) {}
    
    private(set) var nextLineCallCount = 0
    
    func nextLine() -> String {
        nextLineCallCount += 1
        return ""
    }
}

final class BatchedFileSystemIssueLoader {
    private let streamingReader: StreamingReader
    
    init(streamingReader: StreamingReader) {
        self.streamingReader = streamingReader
    }
    
    func loadIssues(completion: (Result<[Issue], Error>) -> Void) {
        _ = streamingReader.nextLine()
        completion(.failure(NSError(domain: "any", code: 0)))
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
        let (sut, _) = makeSUT(readerStub: ["invalid data"])

        var receivedError: Error?
        sut.loadIssues { result in
            if case let .failure(error) = result {
                receivedError = error
            }
        }
        
        XCTAssertNotNil(receivedError)
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        readerStub: [String] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (BatchedFileSystemIssueLoader, StreamingReader) {
        let streamingReader = StreamingReader(stub: readerStub)
        let sut = BatchedFileSystemIssueLoader(streamingReader: streamingReader)
        
        trackForMemoryLeaks(streamingReader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, streamingReader)
    }
}
