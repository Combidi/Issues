//
//  IssuesUIIntegrationTests.swift
//  Issues
//
//  Created by Peter Combee on 22/08/2022.
//

import XCTest
import Issues

final class IssuesLoader {
    
    var loadIssuesCallCount: Int {
        completions.count
    }
    
    private var completions = [([Issue]) -> Void]()
    
    func loadIssues(completion: @escaping ([Issue]) -> Void) {
        completions.append(completion)
    }
    
    func completeIssuesLoading(with issues: [Issue], at index: Int = 0) {
        completions[index](issues)
    }
}

final class IssuesViewController: UITableViewController {
    
    private let loader: IssuesLoader
    
    init(loader: IssuesLoader) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { return nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.loadIssues(completion: { [unowned self] in self.issues = $0 })
    }
    
    private var issues = [Issue]() {
        didSet { tableView.reloadData() }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        issues.count
    }
}

final class IssuesUIIntegrationTests: XCTestCase {
    
    func test_loadsIssuesActionLoadsIssuesFromLoader() {
        let (sut, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadIssuesCallCount, 0, "Expected no loading request before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request once view is loaded")
    }
    
    func test_loadIssuesCompletion_rendersSuccessfullyLoadedIssues() {
        let issue0 = Issue(firstName: "a first name", surname: "a surname", amountOfIssues: 2, birthDate: Date())
        let issue1 = Issue(firstName: "another first name", surname: "another surname", amountOfIssues: 1, birthDate: Date())
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 0)
    
        loader.completeIssuesLoading(with: [issue0, issue1], at: 0)
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 2)
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: IssuesViewController, loader: IssuesLoader) {
        let loader = IssuesLoader()
        let sut = IssuesViewController(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
}

// MARK: Helpers

private extension IssuesViewController {
    private var issuesSection: Int {
        return 0
    }

    func numberOfRenderedIssueViews() -> Int {
        tableView.numberOfRows(inSection: issuesSection)
    }
}

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
