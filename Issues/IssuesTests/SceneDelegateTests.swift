//
//  Created by Peter Combee on 02/09/2022.
//

import XCTest
@testable import Issues

final class SceneDelegateTests: XCTestCase {
    
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = WindowSpy()
        let sut = SceneDelegate()
        sut.window = window
        
        sut.configureWindow()

        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }
}

// MARK: - Helpers

private class WindowSpy: UIWindow {
    private(set) var makeKeyAndVisibleCallCount = 0

    override func makeKeyAndVisible() {
        makeKeyAndVisibleCallCount += 1
    }
}
