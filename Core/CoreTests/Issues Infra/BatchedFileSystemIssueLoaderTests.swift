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
    private let mapper: (String) throws -> [Issue]
    
    init(streamingReader: StreamingReader, mapper: @escaping (String) throws -> [Issue]) {
        self.streamingReader = streamingReader
        self.mapper = mapper
    }
    
    func loadIssues(completion: (Result<[Issue], Error>) -> Void) {
        let _ = streamingReader.nextLine()
        
        do {
            let _ = try mapper("")
        } catch {
            completion(.failure(error))
            
        }
        
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
    
    // MARK: Helpers
    
    private func makeSUT(
        readerStub: [String] = [],
        mapper: @escaping (String) throws -> [Issue] = { _ in [] },
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
