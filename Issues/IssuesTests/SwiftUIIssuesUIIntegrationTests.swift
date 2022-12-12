//
//  Created by Peter Combee on 08/11/2022.
//

import XCTest
import Issues
import Core

final class SwiftUIIssuesUIIntegrationTests: XCTestCase {
    
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
        
        XCTAssertEqual(try sut.numberOfRenderedIssueViews(), 0)
    
        loader.completeIssuesLoading(with: [issue0, issue1], at: 0)
        
        XCTAssertEqual(try sut.numberOfRenderedIssueViews(), 2)
        
        XCTAssertEqual(try sut.renderedName(atIndex: 0), "Peter Combee")
        XCTAssertEqual(try sut.renderedSubject(atIndex: 0), "Phone charger is missing")
        XCTAssertEqual(try sut.renderedSubmissionDate(atIndex: 0), "24 dec. 1990")

        XCTAssertEqual(try sut.renderedName(atIndex: 1), "Luna Combee")
        XCTAssertEqual(try sut.renderedSubject(atIndex: 1), "My game controller is broken")
        XCTAssertEqual(try sut.renderedSubmissionDate(atIndex: 1), "27 okt. 1992")
    }

    func test_loadingIssuesIndicator_isVisibleWhileLoadingIssues_success() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(try sut.isShowingLoadingIndicator(), "Expected loading indicator once view is loaded")
    
        loader.completeIssuesLoading(at: 0)
        
        XCTAssertFalse(try sut.isShowingLoadingIndicator(), "Expected no loading indicator once loading completes successfully")
    }

    func test_loadingIssuesIndicator_isVisibleWhileLoadingIssues_failure() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(try sut.isShowingLoadingIndicator(), "Expected loading indicator once view is loaded")
    
        loader.completeIssuesLoadingWithError()
        
        XCTAssertFalse(try sut.isShowingLoadingIndicator(), "Expected no loading indicator once loading completes with error")
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
    ) -> (sut: IssuesListView, loader: IssuesLoaderSpy) {
        let loader = IssuesLoaderSpy()
        let sut = SwiftUIIssuesUIComposer.compose(withLoader: loader, locale: locale)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut.model, file: file, line: line)
        return (sut, loader)
    }
}

// MARK: Helpers

import ViewInspector

extension IssuesListView: Inspectable {
    private typealias IssueViewType = InspectableView<ViewType.VStack>
    
    private func issueViews() throws -> [IssueViewType] {
        try inspect().findAll(ViewType.VStack.self)
    }
    
    func numberOfRenderedIssueViews() throws -> Int {
        try issueViews().count
    }
    
    func renderedName(atIndex index: Int = 0) throws -> String? {
        try issueView(atIndex: index)?.findAll(ViewType.Text.self)[0].string()
    }
    
    func renderedSubject(atIndex index: Int = 0) throws -> String? {
        try issueView(atIndex: index)?.findAll(ViewType.Text.self)[1].string()
    }
    
    func renderedSubmissionDate(atIndex index: Int = 0) throws -> String? {
        try issueView(atIndex: index)?.findAll(ViewType.Text.self)[2].string()
    }
    
    private func issueView(atIndex index: Int = 0) throws -> IssueViewType? {
        try issueViews()[safe: index]
    }
    
    func isShowingLoadingIndicator() throws -> Bool {
        try !inspect().findAll(ViewType.ProgressView.self).isEmpty
    }
    
    func renderedErrorMessage() -> String? {
        try? inspect().find(ViewType.Text.self).string()
    }
    
    func loadViewIfNeeded() {
        ViewHosting.host(view: self, function: "dop")
    }
}

private extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
