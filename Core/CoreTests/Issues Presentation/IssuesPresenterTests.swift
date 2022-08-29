//
//  Created by Peter Combee on 29/08/2022.
//

import XCTest
import Core

final class IssuesPresenterTests: XCTestCase {
    
    func test_title() {
        XCTAssertEqual(IssuesPresenter.title, "Issues")
    }
    
    func test_loadIssuesActions_requestIssuesFromLoader() {
        let (sut, loader, _) = makeSUT()
                
        sut.loadIssues()
        
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request on load issues command")
    }
    
    func test_loadIssuesActions_presentsMappedIssuesOnSuccessfullLoad() {
        let (sut, loader, view) = makeSUT()
        sut.loadIssues()

        let issue0 = Issue(firstName: "Peter", surname: "Combee", amountOfIssues: 2, birthDate: Date(timeIntervalSince1970: 662072400))
        let issue1 = Issue(firstName: "Luna", surname: "Combee", amountOfIssues: 1, birthDate: Date(timeIntervalSince1970: 720220087))
        loader.completeLoading(with: [issue0, issue1])
        
        let expectedViewModels = [
            IssueViewModel(name: "Peter Combee", amountOfIssues: "2", birthDate: "24 dec. 1990"),
            IssueViewModel(name: "Luna Combee", amountOfIssues: "1", birthDate: "27 okt. 1992"),
        ]
        XCTAssertEqual(view.capturedIssues, [expectedViewModels])
    }
    
    func test_loadIssuesActions_presentsErrorMessageOnFailedLoad() {
        let (sut, loader, view) = makeSUT()
        sut.loadIssues()

        loader.completeLoadingWithError()
        
        XCTAssertEqual(view.capturedMessages, ["Invalid data"])
    }

    func test_loadIssuesActions_doesNotPresentsErrorMessageOnSuccessfullLoad() {
        let (sut, loader, view) = makeSUT()
        sut.loadIssues()

        loader.completeLoading(with: [])
        
        XCTAssertTrue(view.capturedMessages.isEmpty, "Expect no messages on successfull loads")
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
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: IssuesPresenter, loader: LoaderSpy, view: ViewSpy) {
        let loader = LoaderSpy()
        let view = ViewSpy()
        let sut = IssuesPresenter(loader: loader, view: view)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader, view)
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

final class ViewSpy: IssuesView {
    private(set) var capturedIssues = [[IssueViewModel]]()
    func present(issues: [IssueViewModel]) {
        capturedIssues.append(issues)
    }
    
    private(set) var capturedMessages = [String]()
    func present(_ message: String) {
        capturedMessages.append(message)
    }
    
    private(set) var capturedLoadings = [Bool]()
    func presentLoading(_ flag: Bool) {
        capturedLoadings.append(flag)
    }
}


private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
