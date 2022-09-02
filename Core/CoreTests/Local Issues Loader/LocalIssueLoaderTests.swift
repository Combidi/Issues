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

        try! invalidData().write(to: testSpecificFileURL())
        
        let exp = expectation(description: "wait for load completion")
        var mapperError: Error?
        sut.loadIssues {
            if case let .failure(error) = $0 { mapperError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mapperError as? NSError, anyError())
    }

    func test_loadIssues_deliversErrorOnMissingFile() {
        let fileURL = testSpecificFileURL()
        let sut = LocalIssueLoader(fileURL: fileURL, mapper: { data in
            throw anyError()
        })

        try! FileManager.default.removeItem(at: testSpecificFileURL())
                
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
    
    // MARK: Helpers
    
    private func testSpecificFileURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).csv")
    }
    
    private func invalidData() -> Data {
        Data(capacity: 1)
    }
    
    private func fileNotFoundError() -> NSError {
        NSError(domain: "NSCocoaErrorDomain", code: 260)
    }
}

// MARK: Helpers

private func anyError() -> NSError {
    NSError(domain: "any", code: 1)
}
