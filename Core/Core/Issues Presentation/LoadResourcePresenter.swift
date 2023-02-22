//
//  Created by Peter Combee on 22/02/2023.
//

public protocol ResourceErrorView {
    func display(_ viewModel: ResourceLoadingErrorViewModel)
}

public protocol ResourceView {
    associatedtype ResourceViewModel
    
    func display(_ viewModel: ResourceViewModel)
}

public final class LoadResourcePresenter<Resource, View: ResourceView> {
    public typealias Mapper = (Resource) -> View.ResourceViewModel
    
    private let view: View
    private let loadingView: ResourceLoadingView
    private let errorView: ResourceErrorView
    private let mapper: Mapper
    
    public init(
        view: View,
        loadingView: ResourceLoadingView,
        errorView: ResourceErrorView,
        mapper: @escaping Mapper
    ) {
        self.view = view
        self.loadingView = loadingView
        self.errorView = errorView
        self.mapper = mapper
    }
    
    public func didStartLoading() {
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
        errorView.display(ResourceLoadingErrorViewModel(message: nil))
    }
    
    public func didFinishLoadingWithError() {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        errorView.display(ResourceLoadingErrorViewModel(message: "Invalid data"))
    }
    
    public func didFinishLoading(with resource: Resource) {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        view.display(mapper(resource))
    }
}
