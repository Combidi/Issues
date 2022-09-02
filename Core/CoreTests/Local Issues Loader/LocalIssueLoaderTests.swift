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
        
        let exp = expectation(description: "wait for load completion")
        var mapperError: Error?
        sut.loadIssues {
            if case let .failure(error) = $0 { mapperError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertNotNil(mapperError, "Expected load to fail")
    }
    
    // MARK: Helpers
    
    private func testSpecificFileURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
    }
}

// MARK: Helpers

private func anyError() -> Error {
    NSError(domain: "any", code: 1)
}
