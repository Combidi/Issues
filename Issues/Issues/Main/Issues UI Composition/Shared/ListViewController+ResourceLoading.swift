//
//  Created by Peter Combee on 10/05/2023.
//

import Core

extension ListViewController: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        display(isLoading: viewModel.isLoading)
    }
}

extension ListViewController: ResourceErrorView {
    public func display(_ viewModel: ResourceLoadingErrorViewModel) {
        display(message: viewModel.message)
    }
}
