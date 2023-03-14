//
//  Created by Peter Combee on 02/03/2023.
//

import XCTest

final class StreamingReader {
    init(stub: [String] = []) {}
    
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
    
    func loadIssues(completion: (Error) -> Void) {
        _ = streamingReader.nextLine()
        completion(NSError(domain: "any", code: 0))
    }
}

class BatchedFileSystemIssueLoaderTests: XCTestCase {
     
    func test_doesNotRequestLinesOnInit() {
        
        let streamingReader = StreamingReader()
        let _ = BatchedFileSystemIssueLoader(streamingReader: streamingReader)
                
        XCTAssertEqual(streamingReader.nextLineCallCount, 0)
    }
    
    func test_loadIssues_requestsNextLine() {
        let streamingReader = StreamingReader()
        let sut = BatchedFileSystemIssueLoader(streamingReader: streamingReader)
                
        sut.loadIssues { _ in }
        
        XCTAssertEqual(streamingReader.nextLineCallCount, 1)
    }
    
    func test_loadIssues_deliversErrorOnMappingError() {
        let streamingReader = StreamingReader(stub: [
            "invalid data"
        ])
        let sut = BatchedFileSystemIssueLoader(streamingReader: streamingReader)

        var receivedError: Error?
        sut.loadIssues { receivedError = $0 }
        
        XCTAssertNotNil(receivedError)
    }
}
