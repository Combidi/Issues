//
//  Created by Peter Combee on 10/05/2023.
//

import XCTest
import Core

final class SharedLocalizationTests: XCTestCase, LocalizationTest {
    
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = Bundle(for: LoadResourcePresenter<String, DummyView>.self)
        
        assertLocalizedKeysAndValuesExist(in: bundle, table)
    }
}

// MARK: Helpers

private class DummyView: ResourceView {
    func display(_ viewModel: String) {}
}
