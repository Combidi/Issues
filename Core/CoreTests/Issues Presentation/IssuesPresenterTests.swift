//
//  Created by Peter Combee on 29/08/2022.
//

import XCTest
import Core

final class IssuesPresenterTests: XCTestCase {
    
    func test_title_isLocalized() {
        XCTAssertEqual(IssuesPresenter.title, localized("ISSUES_VIEW_TITLE"))
    }
    
    func test_loadIssuesActions_requestIssuesFromLoader() {
        let (sut, loader, _) = makeSUT()
                
        sut.loadIssues()
        
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request on load issues command")
    }
    
    func test_loadIssuesActions_presentsMappedIssuesOnSuccessfullLoad() {
        let (sut, loader, view) = makeSUT(locale: Locale(identifier: "en_US_POSIX"))
        sut.loadIssues()

        let issue0 = Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 662072400), subject: "Phone charger is missing")
        let issue1 = Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 720220087), subject: "My game controller is broken")
        loader.completeLoading(with: [issue0, issue1])
        
        let expectedViewModels = [
            IssueViewModel(name: "Peter Combee", submissionDate: "Dec 24, 1990", subject: "Phone charger is missing"),
            IssueViewModel(name: "Luna Combee", submissionDate: "Oct 27, 1992", subject: "My game controller is broken"),
        ]
        XCTAssertEqual(view.capturedIssues, [expectedViewModels])
    }
    
    func test_loadIssuesActions_presentsErrorMessageOnFailedLoad() {
        let (sut, loader, view) = makeSUT()
        sut.loadIssues()

        loader.completeLoadingWithError()
        
        XCTAssertEqual(view.capturedMessages, ["Invalid data"])
    }

    func test_loadIssuesActions_presentsLoadingDuringLoad() {
        let (sut, loader, view) = makeSUT()

        XCTAssertTrue(view.capturedLoadings.isEmpty, "Expect no loading before loading starts")

        sut.loadIssues()

        XCTAssertEqual(view.capturedLoadings, [true], "Expect to present loading during loading")
        
        loader.completeLoading(with: [])
        
        XCTAssertEqual(view.capturedLoadings, [true, false], "Expect to stop presenting loading once loading finished successfully")

        loader.completeLoadingWithError()

        XCTAssertEqual(view.capturedLoadings, [true, false, false], "Expect to stop presenting loading once loading finished with error")
    }

    func test_loadIssuesActions_hidesMessageOnSuccessfullLoad() {
        let (sut, loader, view) = makeSUT()

        sut.loadIssues()
        
        loader.completeLoading(with: [])

        XCTAssertEqual(view.capturedMessages, [nil], "Expect to hide message on successfull load")
    }
    
    // MARK: Helpers
    
    private func makeSUT(
        locale: Locale = .current,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: IssuesPresenter, loader: LoaderSpy, view: ViewSpy) {
        let loader = LoaderSpy()
        let view = ViewSpy()
        let sut = IssuesPresenter(loader: loader, loadingView: view, errorView: view, view: view, locale: locale)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader, view)
    }
    
    private func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Issues"
        let bundle = Bundle(for: IssuesPresenter.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}

// MARK: Helpers

final private class LoaderSpy: IssuesLoader {
    private var loadCompletions = [IssuesLoader.Completion]()
    
    var loadIssuesCallCount: Int {
        loadCompletions.count
    }

    func loadIssues(completion: @escaping Completion) {
        loadCompletions.append(completion)
    }
    
    func completeLoading(with issues: [Issue], at index: Int = 0) {
        loadCompletions[index](.success(issues))
    }

    func completeLoadingWithError(at index: Int = 0) {
        loadCompletions[index](.failure(NSError(domain: "any", code: 0)))
    }
}

final class ViewSpy: IssuesView, IssuesLoadingView, IssuesErrorView {
    private(set) var capturedIssues = [[IssueViewModel]]()
    func display(issues: [IssueViewModel]) {
        capturedIssues.append(issues)
    }
    
    private(set) var capturedMessages = [String?]()
    func display(message: String?) {
        capturedMessages.append(message)
    }
    
    private(set) var capturedLoadings = [Bool]()
    func display(isLoading: Bool) {
        capturedLoadings.append(isLoading)
    }
}


private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
