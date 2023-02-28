//
//  Created by Peter Combee on 22/08/2022.
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
    
    func test_loadMoreActions_requestMoreFromLoader() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeIssuesLoading()
        
        XCTAssertEqual(loader.loadMoreCallCount, 0, "Expected no request before load more action")
        
        sut.simulateLoadMoreIssuesAction()
        XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected request load more request")
        
        sut.simulateLoadMoreIssuesAction()
        XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected no request while loading more")
        
        loader.completeLoadMore(lastPage: false)
        sut.simulateLoadMoreIssuesAction()
        XCTAssertEqual(loader.loadMoreCallCount, 2, "Expected request after load more completed with more pages")

        loader.completeLoadMoreWithError()
        sut.simulateLoadMoreIssuesAction()
        XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected request after load more failure")

        loader.completeLoadMore(lastPage: true)
        sut.simulateLoadMoreIssuesAction()
        XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected no request after loading all pages")
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
    
    func test_loadingMoreIndicator_isVisibleWhileLoadingMore() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no loading indicator once view is loaded")

        loader.completeIssuesLoading()
        XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no loading indicator once loading completes successfully")

        sut.simulateLoadMoreIssuesAction()
        XCTAssertTrue(sut.isShowingLoadMoreIndicator, "Expected loading indicator on load more action")

        loader.completeLoadMore(lastPage: false)

        XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no loading indicator once user initiated loading completes successfully")

        sut.simulateLoadMoreIssuesAction()
        XCTAssertTrue(sut.isShowingLoadMoreIndicator, "Expected loading indicator on second load more action")

        loader.completeLoadMoreWithError()
        XCTAssertFalse(sut.isShowingLoadMoreIndicator, "Expected no loading indicator once user initiated loading completes with error")
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
    
    func test_loadMoreCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeIssuesLoading()
        sut.simulateLoadMoreIssuesAction()
        
        let exp = expectation(description: "wait for load more completion")
        DispatchQueue.global().async {
            loader.completeLoadMore(lastPage: true)
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
    
    func test_loadMoreCompletion_rendersErrorMessageOnError() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeIssuesLoading()
        
        sut.simulateLoadMoreIssuesAction()
        loader.completeLoadMoreWithError()
        
        XCTAssertEqual(sut.renderedLoadMoreErrorMessage(), "Invalid data")
    }

    // MARK: Helpers
    
    private func makeSUT(
        locale: Locale = .current,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: IssuesLoaderSpy) {
        let loader = IssuesLoaderSpy()
        let sut = IssuesUIComposer.compose(withLoader: loader, locale: locale) as! ListViewController
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
    
    func renderedLoadMoreErrorMessage() -> String? {
        renderedLoadMoreView()?.message
    }
    
    func simulateLoadMoreIssuesAction() {
        let index = IndexPath(row: 0, section: loadMoreSection)
        guard let cell = cell(at: index) else { return }
        tableView.delegate?.tableView?(tableView, willDisplay: cell, forRowAt: index)
    }
    
    var isShowingLoadMoreIndicator: Bool {
        renderedLoadMoreView()?.isLoading ?? false
    }
    
    private func renderedLoadMoreView() -> LoadMoreCell? {
        cell(at: IndexPath(row: 0, section: loadMoreSection)) as? LoadMoreCell
    }
}

private final class IssuesLoaderSpy: PaginatedIssuesLoader {
    
    var loadIssuesCallCount: Int {
        loadCompletions.count
    }
    
    var loadMoreCallCount: Int {
        loadMoreLoaders.map(\.loadCompletions.count).reduce(0, +)
    }
    
    private var loadCompletions = [Completion]()
    private var loadMoreLoaders = [IssuesLoaderSpy]()
    
    func loadIssues(completion: @escaping Completion) {
        loadCompletions.append(completion)
    }
    
    func completeIssuesLoading(with issues: [Issue] = []) {
        let paginated = PaginatedIssues(issues: issues, loadMore: { [weak self] in
            let loadMoreLoader = IssuesLoaderSpy()
            self?.loadMoreLoaders.append(loadMoreLoader)
            return loadMoreLoader
        })
        loadCompletions.last?(.success(paginated))
    }
    
    func completeIssuesLoadingWithError() {
        loadCompletions.last?(.failure(NSError(domain: "any", code: 1)))
    }
    
    func completeLoadMore(lastPage: Bool) {
        let paginated = PaginatedIssues(issues: [], loadMore: lastPage ? nil : { [weak self] in
            let loadMoreLoader = IssuesLoaderSpy()
            self?.loadMoreLoaders.append(loadMoreLoader)
            return loadMoreLoader
        })

        loadMoreLoaders.last?.loadCompletions.last?(.success(paginated))
    }
    
    func completeLoadMoreWithError() {
        loadMoreLoaders.last?.loadCompletions.last?(.failure(NSError(domain: "any", code: 1)))
    }
}

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
