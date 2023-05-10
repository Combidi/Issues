//
//  Created by Peter Combee on 10/05/2023.
//

import XCTest
import Issues
import Core

final class IssuesUIIntegrationTests: XCTestCase {
    
    func test_issuesView_hasTitle() {
        let (sut, _) = makeSUT()
    
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, "Issues")
    }
    
    func test_loadsIssuesActionLoadsIssuesFromLoader() {
        let (sut, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadIssuesCallCount, 0, "Expected no loading request before view is loaded")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request once view is loaded")
    }
        
    func test_loadIssuesCompletion_rendersSuccessfullyLoadedIssues() {
        let issue0 = Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 662072400), subject: "Phone charger is missing")
        let issue1 = Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 720220087), subject: "My game controller is broken")
        let (sut, loader) = makeSUT(locale: Locale(identifier: "NL"))
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 0)
    
        loader.completeIssuesLoading(with: [issue0, issue1])
        
        XCTAssertEqual(sut.numberOfRenderedIssueViews(), 2)
        
        XCTAssertEqual(sut.renderedName(atIndex: 0), "Peter Combee")
        XCTAssertEqual(sut.renderedSubject(atIndex: 0), "Phone charger is missing")
        XCTAssertEqual(sut.renderedSubmissionDate(atIndex: 0), "24 dec. 1990")

        XCTAssertEqual(sut.renderedName(atIndex: 1), "Luna Combee")
        XCTAssertEqual(sut.renderedSubject(atIndex: 1), "My game controller is broken")
        XCTAssertEqual(sut.renderedSubmissionDate(atIndex: 1), "27 okt. 1992")
    }

    func test_loadingIssuesIndicator_isVisibleWhileLoadingIssues_success() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
    
        loader.completeIssuesLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")
    }

    func test_loadingIssuesIndicator_isVisibleWhileLoadingIssues_failure() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
    
        loader.completeIssuesLoadingWithError()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes with error")
    }
    
    func test_loadIssuesCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeIssuesLoading()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
        
    func test_loadIssuesCompletion_rendersErrorMessageOnError() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.renderedErrorMessage(), nil)

        loader.completeIssuesLoadingWithError()
        XCTAssertEqual(sut.renderedErrorMessage(), "Invalid data")
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        locale: Locale = .current,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: IssuesLoaderSpy) {
        let loader = IssuesLoaderSpy()
        let sut = PaginatedIssuesUIComposer.compose(withLoader: loader.loadIssues, locale: locale) as! ListViewController
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
}

// MARK: Helpers

private extension ListViewController {
    
    private var issuesSection: Int { 0 }
    private var loadMoreSection: Int { 1 }

    func numberOfRenderedIssueViews() -> Int {
        numberOfRows(in: issuesSection)
    }
    
    private func numberOfRows(in section: Int) -> Int {
        tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
    }

    func renderedName(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.nameLabel.text
    }
    
    func renderedSubject(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.subjectLabel.text
    }

    func renderedSubmissionDate(atIndex index: Int = 0) -> String? {
        issueView(atIndex: index)?.submissionDateLabel.text
    }
    
    private func issueView(atIndex index: Int = 0) -> IssueCell? {
        cell(at: IndexPath(row: index, section: issuesSection)) as? IssueCell
    }
    
    private func cell(at indexPath: IndexPath) -> UITableViewCell? {
        guard numberOfRows(in: indexPath.section) > indexPath.row else {
            return nil
        }
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    var isShowingLoadingIndicator: Bool {
        activityIndicator.isAnimating
    }
    
    func renderedErrorMessage() -> String? {
        errorLabel.text
    }
}

private final class IssuesLoaderSpy {
    typealias LoadCompletion = (Result<Paginated<Issue>, Error>) -> Void
    
    var loadIssuesCallCount: Int {
        loadCompletions.count
    }
        
    private var loadCompletions = [LoadCompletion]()
    private var loadMoreCompletions = [LoadCompletion]()
    
    func loadIssues(completion: @escaping LoadCompletion) {
        loadCompletions.append(completion)
    }
    
    func completeIssuesLoading(with issues: [Issue] = []) {
        let paginated = Paginated(models: issues, loadMore: { [weak self] completion in
            self?.loadMoreCompletions.append(completion)
        })
        loadCompletions.last?(.success(paginated))
    }
    
    func completeIssuesLoadingWithError() {
        loadCompletions.last?(.failure(NSError(domain: "any", code: 1)))
    }    
}

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
