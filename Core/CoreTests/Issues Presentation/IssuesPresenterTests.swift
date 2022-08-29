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
        loader.loadIssues { result in
            if case let .success(issues) = result {
                let viewModels = issues.map { issue -> IssueViewModel in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    
                    return IssueViewModel(
                        name: issue.firstName + " " + issue.surname,
                        amountOfIssues: String(issue.amountOfIssues),
                        birthDate: dateFormatter.string(from: issue.birthDate))
                }
                self.view.present(issues: viewModels)
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
}

final class IssuesView {
    private(set) var capturedIssues = [[IssueViewModel]]()
    func present(issues: [IssueViewModel]) {
        capturedIssues.append(issues)
    }
}

final class IssuesPresenterTests: XCTestCase {
    
    func test_loadIssuesActions_requestIssuesFromLoader() {
        
        let loader = LoaderSpy()
        let sut = IssuesPresenter(loader: loader, view: IssuesView())
        
        sut.loadIssues()
        
        XCTAssertEqual(loader.loadIssuesCallCount, 1, "Expected a loading request on load issues command")
    }
    
    func test_loadIssuesActions_displaysMappedIssuesOnSuccessfullLoad() {

        let loader = LoaderSpy()
        let view = IssuesView()
        let sut = IssuesPresenter(loader: loader, view: view)
        
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
}
