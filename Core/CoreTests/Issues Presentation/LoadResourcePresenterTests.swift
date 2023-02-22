//
//  LoadResourcePresenterTests.swift
//  CoreTests
//
//  Created by Peter Combee on 22/02/2023.
//

import XCTest
import Core

struct ResourceLoadingViewModel: Equatable {
    let isLoading: Bool
}

private final class LoadResourcePresenter {
    private let view: ViewSpy
    
    init(view: ViewSpy) {
        self.view = view
    }
    
    func didStartLoading() {
        view.display(ResourceLoadingViewModel(isLoading: true))
    }
}

final class LoadResourcePresenterTests: XCTestCase {
    
    func test_didStartLoading_displaysLoading() {
        let view = ViewSpy()
        let sut = LoadResourcePresenter(view: view)
        
        XCTAssertEqual(view.captures, [])

        sut.didStartLoading()
        
        XCTAssertEqual(view.captures, [ResourceLoadingViewModel(isLoading: true)])
    }
}

private class ViewSpy {
    
    private(set) var captures = [ResourceLoadingViewModel]()
    
    func display(_ viewModel: ResourceLoadingViewModel) {
        captures.append(viewModel)
    }
}
