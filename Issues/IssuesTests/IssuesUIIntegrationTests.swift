//
//  IssuesUIIntegrationTests.swift
//  Issues
//
//  Created by Peter Combee on 22/08/2022.
//

import XCTest

final class IssuesLoader {
    
    private(set) var loadIssuesCallCount = 0
    
    func loadIssues() {
        loadIssuesCallCount += 1
    }
}

final class IssuesViewController: UIViewController {
    
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { return nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.loadIssues()
    }
}

final class IssuesUIIntegrationTests: XCTestCase {

    func test_loadsIssuesActionLoadsIssuesFromLoader() {
        let loader = IssuesLoader()
        let sut = IssuesViewController(loader: loader)
        
        XCTAssertEqual(loader.loadIssuesCallCount, 0, "Expected no loading request before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request once view is loaded")
    }
}
