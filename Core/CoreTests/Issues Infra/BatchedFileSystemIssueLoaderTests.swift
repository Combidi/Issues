//
//  Created by Peter Combee on 02/03/2023.
//

import XCTest

final class StreamingReader {
    private(set) var nextLineCallCount = 0
}

final class BatchedFileSystemIssueLoader {
    init(streamingReader: StreamingReader) {
        
    }
}

class BatchedFileSystemIssueLoaderTests: XCTestCase {
 
    func test_doesNotRequestLinesOnInit() {
        
        let streamingReader = StreamingReader()
        let _ = BatchedFileSystemIssueLoader(streamingReader: streamingReader)
                
        XCTAssertEqual(streamingReader.nextLineCallCount, 0)
    }
}
