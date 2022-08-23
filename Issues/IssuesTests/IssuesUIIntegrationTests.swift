//
//  IssuesUIIntegrationTests.swift
//  Issues
//
//  Created by Peter Combee on 22/08/2022.
//

import XCTest
import Issues

protocol IssueLoader {
    typealias Result = Swift.Result<[Issue], Error>
    typealias Completion = (Result) -> Void
    
    func loadIssues(completion: @escaping Completion)
}

final class IssuesLoaderSpy: IssueLoader {
    
    typealias Result = Swift.Result<[Issue], Error>
    typealias Completion = (Result) -> Void
    
    var loadIssuesCallCount: Int {
        completions.count
    }
    
    private var completions = [Completion]()
    
    func loadIssues(completion: @escaping Completion) {
        completions.append(completion)
    }
    
    func completeIssuesLoading(with issues: [Issue] = [], at index: Int = 0) {
        completions[index](.success(issues))
    }
    
    func completeIssuesLoadingWithError(at index: Int = 0) {
        completions[index](.failure(NSError(domain: "any", code: 1)))
    }
}

final class IssueCell: UITableViewCell {
    let firstNameLabel = UILabel()
    let surNameLabel = UILabel()
    let issueCountLabel = UILabel()
    let birthDateLabel = UILabel()
}

final class IssuesViewController: UITableViewController {
    
    private let loader: IssuesLoaderSpy
    
    init(loader: IssuesLoaderSpy) {
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { return nil }
    
    private(set) var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private(set) var errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        loader.loadIssues(completion: { [weak self] result in
            if Thread.isMainThread {
                switch result {
                case let .success(issues):
                    self?.issues = issues
                    self?.activityIndicator.stopAnimating()
                case .failure:
                    self?.errorLabel.text = "Invalid data"
                }
            } else {
                switch result {
                case let .success(issues):
                    DispatchQueue.main.async {
                        self?.issues = issues
                        self?.activityIndicator.stopAnimating()
                    }
                case .failure:
                    self?.errorLabel.text = "Invalid data"
                }
            }
        })
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        cell.birthDateLabel.text = dateFormatter.string(for: issues[indexPath.row].birthDate)
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
        let issue0 = Issue(firstName: "a first name", surname: "a surname", amountOfIssues: 2, birthDate: Date(timeIntervalSince1970: 662072400))
        let issue1 = Issue(firstName: "another first name", surname: "another surname", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 720220087))
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 0)
    
        loader.completeIssuesLoading(with: [issue0, issue1], at: 0)
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 2)
        
        XCTAssertEqual(sut.renderedFirstName(atIndex: 0), "a first name")
        XCTAssertEqual(sut.renderedSurname(atIndex: 0), "a surname")
        XCTAssertEqual(sut.renderedIssueCount(atIndex: 0), "2")
        XCTAssertEqual(sut.renderedBirthDate(atIndex: 0), "24 dec. 1990")

        XCTAssertEqual(sut.renderedFirstName(atIndex: 1), "another first name")
        XCTAssertEqual(sut.renderedSurname(atIndex: 1), "another surname")
        XCTAssertEqual(sut.renderedIssueCount(atIndex: 1), "1")
        XCTAssertEqual(sut.renderedBirthDate(atIndex: 1), "27 okt. 1992")
    }
    
    func test_loadingIssuesIndicator_isVisibleWhileLoadingIssues() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
    
        sut.loadViewIfNeeded()
        loader.completeIssuesLoading(at: 0)
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")
    }
    
    func test_loadIssuesCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeIssuesLoading(at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadIssuesCompletion_rendersErrorMessageOnError() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.renderedErrorMessage(), nil)

        loader.completeIssuesLoadingWithError(at: 0)
        XCTAssertEqual(sut.renderedErrorMessage(), "Invalid data")
    }

    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: IssuesViewController, loader: IssuesLoaderSpy) {
        let loader = IssuesLoaderSpy()
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

    func renderedBirthDate(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.birthDateLabel.text
    }
    
    private func issueView(atIndex index: Int = 0) -> IssueCell? {
        let dataSource = tableView.dataSource
        let index = IndexPath(row: index, section: issuesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index) as? IssueCell
    }
    
    var isShowingLoadingIndicator: Bool {
        activityIndicator.isAnimating
    }
    
    func renderedErrorMessage() -> String? {
        errorLabel.text
    }
}

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
