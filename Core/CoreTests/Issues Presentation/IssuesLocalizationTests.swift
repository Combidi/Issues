//
//  Created by Peter Combee on 29/08/2022.
//

import XCTest
import Core

final class IssuesLocalizationTests: XCTestCase, LocalizationTest {
    
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Issues"
        let bundle = Bundle(for: IssueViewModelMapper.self)
        
        assertLocalizedKeysAndValuesExist(in: bundle, table)
    }
}
