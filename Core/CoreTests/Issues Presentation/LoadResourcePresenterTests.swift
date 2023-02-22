//
//  LoadResourcePresenterTests.swift
//  CoreTests
//
//  Created by Peter Combee on 22/02/2023.
//

import XCTest
import Core

private final class LoadResourcePresenter {
    private let view: ViewSpy
    
    init(view: ViewSpy) {
        self.view = view
    }
    
    func didStartLoading() {
        view.displayLoading(true)
    }
}

final class LoadResourcePresenterTests: XCTestCase {
    
    func test_didStartLoading_displaysLoading() {
        let view = ViewSpy()
        let sut = LoadResourcePresenter(view: view)
        
        XCTAssertEqual(view.capturedDisplayLoading, [])

        sut.didStartLoading()
        
        XCTAssertEqual(view.capturedDisplayLoading, [true])
    }
}

private class ViewSpy {
    
    private(set) var capturedDisplayLoading = [Bool]()
    
    func displayLoading(_ flag: Bool) {
        capturedDisplayLoading.append(flag)
    }
}
