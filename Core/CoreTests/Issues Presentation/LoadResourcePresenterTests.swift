//
//  LoadResourcePresenterTests.swift
//  CoreTests
//
//  Created by Peter Combee on 22/02/2023.
//

import XCTest
import Core

struct ResourceLoadingViewModel {
    let isLoading: Bool
}

struct ResourceLoadingErrorViewModel {
    let message: String?
}

private final class LoadResourcePresenter<Resource> {
    private let view: ViewSpy
    private let mapper: (Resource) -> String
    
    init(view: ViewSpy, mapper: @escaping (Resource) -> String) {
        self.view = view
        self.mapper = mapper
    }
    
    func didStartLoading() {
        view.display(ResourceLoadingViewModel(isLoading: true))
        view.display(ResourceLoadingErrorViewModel(message: nil))
    }
    
    func didFinishLoadingWithError() {
        view.display(ResourceLoadingViewModel(isLoading: false))
        view.display(ResourceLoadingErrorViewModel(message: "Invalid data"))
    }
    
    func didFinishLoading(with resource: Resource) {
        view.display(ResourceLoadingViewModel(isLoading: false))
        view.display(mapper(resource))
    }
}

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
    
    func test_didFinishLoadingWithError_displaysShowsErrorAndStopsLoading() {
        let (sut, view) = makeSUT()
        
        sut.didFinishLoadingWithError()
        
        XCTAssertEqual(view.messages, [
            .display(isLoading: false),
            .display(errorMessage: "Invalid data")
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
    
    private typealias SUT = LoadResourcePresenter<String>
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line,
        mapper: @escaping (String) -> String = { $0 }
    ) -> (SUT, ViewSpy) {
        let view = ViewSpy()
        let sut = SUT(view: view, mapper: mapper)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }
}

private class ViewSpy {
    
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
