//
//  Created by Peter Combee on 20/04/2023.
//

import XCTest
@testable import Issues

final class IssuesAcceptanceTests: XCTestCase {

    func test_onLaunch_displaysIssues() {

        let sut = SceneDelegate()
        sut.window = UIWindow()
        sut.configureWindow()

        let nav = sut.window?.rootViewController as? UINavigationController
        let issuesViewController = nav?.topViewController as! ListViewController
        
        issuesViewController.loadViewIfNeeded()

        XCTAssertEqual(issuesViewController.numberOfRenderedIssueViews(), 6171)
    }
}
