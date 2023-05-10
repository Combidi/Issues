//
//  Created by Peter Combee on 10/05/2023.
//

import XCTest

final class IssuesUIAcceptanceTests: XCTestCase {
    
    func test_onLaunch_displaysLocalIssues() {
        let app = XCUIApplication()
        
        app.launch()
        
        XCTAssertEqual(app.cells.count, 3)
    }
}
