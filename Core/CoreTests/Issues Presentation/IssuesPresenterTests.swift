//
//  Created by Peter Combee on 29/08/2022.
//

import XCTest
import Core

final class IssuesPresenter {
    private let loader: IssuesLoader
    private let view: IssuesView
    
    init(loader: IssuesLoader, view: IssuesView) {
        self.loader = loader
        self.view = view
    }
    
    func loadIssues() {
        loader.loadIssues { [weak view] result in
            view?.present("Invalid data")
            if case let .success(issues) = result {
                let viewModels = issues.map { issue -> IssueViewModel in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    
                    return IssueViewModel(
                        name: issue.firstName + " " + issue.surname,
                        amountOfIssues: String(issue.amountOfIssues),
                        birthDate: dateFormatter.string(from: issue.birthDate))
                }
                view?.present(issues: viewModels)
            }
        }
    }
}

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

    func completeLoading(with error: Error, at index: Int = 0) {
        loadCompletions[index](.failure(error))
    }
}

final class IssuesView {
    private(set) var capturedIssues = [[IssueViewModel]]()
    func present(issues: [IssueViewModel]) {
        capturedIssues.append(issues)
    }
    
    private(set) var capturedMessages = [String]()
    func present(_ message: String) {
        capturedMessages.append(message)
    }
}

final class IssuesPresenterTests: XCTestCase {
    
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

        loader.completeLoading(with: NSError(domain: "any", code: 0))
        
        XCTAssertEqual(view.capturedMessages, ["Invalid data"])
    }
    
    // MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: IssuesPresenter, loader: LoaderSpy, view: IssuesView) {
        let loader = LoaderSpy()
        let view = IssuesView()
        let sut = IssuesPresenter(loader: loader, view: view)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader, view)
    }
}

// MARK: Helpers

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been delocated. Potential memory leak", file: file, line: line)
        }
    }
}
