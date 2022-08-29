//
//  Created by Peter Combee on 29/08/2022.
//

import XCTest
import Core

final class IssuesPresenter {
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
    }
    
    func loadIssues() {
        loader.loadIssues { _ in }
    }
}

final private class LoaderSpy: IssuesLoader {
    private(set) var loadCommentsCallCount = 0
    func loadIssues(completion: @escaping Completion) {
        loadCommentsCallCount += 1
    }
}

final class IssuesPresenterTests: XCTestCase {
    
    func test_loadIssuesPerformsLoadCommand() {
        
        let loader = LoaderSpy()
        let sut = IssuesPresenter(loader: loader)
        
        sut.loadIssues()
        
        XCTAssertEqual(loader.loadCommentsCallCount, 1, "Expected a loading request on load issues command")
    }
}
