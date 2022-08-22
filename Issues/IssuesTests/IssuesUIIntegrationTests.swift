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

final class IssueCell: UITableViewCell {
    let firstNameLabel = UILabel()
    let surNameLabel = UILabel()
    let issueCountLabel = UILabel()
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = IssueCell()
        cell.firstNameLabel.text = issues[indexPath.row].firstName
        cell.surNameLabel.text = issues[indexPath.row].surname
        cell.issueCountLabel.text = String(issues[indexPath.row].amountOfIssues)
        return cell
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
        
        XCTAssertEqual(sut.renderedFirstName(atIndex: 0), "a first name")
        XCTAssertEqual(sut.renderedSurname(atIndex: 0), "a surname")
        XCTAssertEqual(sut.renderedIssueCount(atIndex: 0), "2")
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

    func renderedFirstName(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.firstNameLabel.text
    }

    func renderedSurname(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.surNameLabel.text
    }
    
    func renderedIssueCount(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.issueCountLabel.text
    }
    
    private func issueView(atIndex index: Int = 0) -> IssueCell? {
        let dataSource = tableView.dataSource
        let index = IndexPath(row: index, section: issuesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index) as? IssueCell
    }
}

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
