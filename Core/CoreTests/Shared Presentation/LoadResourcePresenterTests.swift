//
//  Created by Peter Combee on 22/02/2023.
//

import XCTest
import Core

final class LoadResourcePresenterTests: XCTestCase {
    
    func test_doesNotSendMessagesOnCreation() {
        let (_, view) = makeSUT()

        XCTAssertEqual(view.messages, [])
    }
    
    func test_didStartLoading_displaysLoadingAndHidesError() {
        let (sut, view) = makeSUT()

        sut.didStartLoading()
        
        XCTAssertEqual(view.messages, [
            .display(isLoading: true),
            .display(errorMessage: nil)
        ])
    }
    
    func test_didFinishLoadingWithError_displaysErrorAndStopsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didFinishLoadingWithError()
        
        XCTAssertEqual(view.messages, [
            .display(isLoading: false),
            .display(errorMessage: localized("LOAD_RESOURCE_ERROR"))
        ])
    }
    
    func test_didFinishLoading_displaysDisplaysMappedResourceAndStopsLoading() {
        let (sut, view) = makeSUT(mapper: { resource in return resource.uppercased() })

        sut.didFinishLoading(with: "resource")
        
        XCTAssertEqual(view.messages, [
            .display(isLoading: false),
            .display(resourceViewModel: "RESOURCE")
        ])
    }

    // MARK: Helpers
    
    private typealias SUT = LoadResourcePresenter<String, ViewSpy>
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line,
        mapper: @escaping (String) -> String = { $0 }
    ) -> (SUT, ViewSpy) {
        let view = ViewSpy()
        let sut = SUT(view: view, loadingView: view, errorView: view, mapper: mapper)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
    
    private func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Shared"
        let bundle = Bundle(for: SUT.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        return value
    }
}

// MARK: Helpers

private class ViewSpy: ResourceView, ResourceLoadingView, ResourceErrorView {
    
    typealias ResourceViewModel = String
    
    enum Message: Hashable {
        case display(isLoading: Bool)
        case display(errorMessage: String?)
        case display(resourceViewModel: String)
    }
    
    private(set) var messages = Set<Message>()
    
    func display(_ viewModel: ResourceLoadingViewModel) {
        messages.insert(.display(isLoading: viewModel.isLoading))
    }
    
    func display(_ viewModel: ResourceLoadingErrorViewModel) {
        messages.insert(.display(errorMessage: viewModel.message))
    }
    
    func display(_ viewModel: String) {
        messages.insert(.display(resourceViewModel: viewModel))
    }
}
