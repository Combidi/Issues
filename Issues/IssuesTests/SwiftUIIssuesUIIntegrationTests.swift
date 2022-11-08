//
//  Created by Peter Combee on 08/11/2022.
//

import XCTest
import Issues
import Core

final class SwiftUIIssuesUIIntegrationTests: XCTestCase {
    
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
    
        loader.completeIssuesLoading(with: [issue0, issue1], at: 0)
        
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
    
        loader.completeIssuesLoading(at: 0)
        
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
    
    private func makeSUT(
        locale: Locale = .current,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: IssuesViewController, loader: IssuesLoaderSpy) {
        let loader = IssuesLoaderSpy()
        let sut = IssuesUIComposer.compose(withLoader: loader, locale: locale) as! IssuesViewController
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

private final class IssuesLoaderSpy: IssuesLoader {
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

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
