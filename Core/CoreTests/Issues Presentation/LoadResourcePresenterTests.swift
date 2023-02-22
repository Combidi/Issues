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

private final class LoadResourcePresenter {
    private let view: ViewSpy
    
    init(view: ViewSpy) {
        self.view = view
    }
    
    func didStartLoading() {
        view.display(ResourceLoadingViewModel(isLoading: true))
        view.display(ResourceLoadingErrorViewModel(message: nil))
    }
}

final class LoadResourcePresenterTests: XCTestCase {
    
    func test_didStartLoading_displaysLoadingAndHidesError() {
        let view = ViewSpy()
        let sut = LoadResourcePresenter(view: view)
        
        XCTAssertEqual(view.messages, [])

        sut.didStartLoading()
        
        XCTAssertEqual(view.messages, [
            .display(isLoading: true),
            .display(errorMessage: nil)
        ])
    }
}

private class ViewSpy {
    
    enum Message: Hashable {
        case display(isLoading: Bool)
        case display(errorMessage: String?)
    }
    
    private(set) var messages = Set<Message>()
    
    func display(_ viewModel: ResourceLoadingViewModel) {
        messages.insert(.display(isLoading: viewModel.isLoading))
    }
    
    func display(_ viewModel: ResourceLoadingErrorViewModel) {
        messages.insert(.display(errorMessage: viewModel.message))
    }
}
