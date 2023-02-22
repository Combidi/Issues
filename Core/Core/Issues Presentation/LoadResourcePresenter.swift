//
//  Created by Peter Combee on 22/02/2023.
//

public struct ResourceLoadingViewModel {
    public let isLoading: Bool
}

public struct ResourceLoadingErrorViewModel {
    public let message: String?
}

public protocol ResourceView {
    associatedtype ResourceViewModel
    
    func display(_ viewModel: ResourceLoadingViewModel)
    func display(_ viewModel: ResourceLoadingErrorViewModel)
    func display(_ viewModel: ResourceViewModel)
}

public final class LoadResourcePresenter<Resource, View: ResourceView> {
    public typealias Mapper = (Resource) -> View.ResourceViewModel
    
    private let view: View
    private let mapper: Mapper
    
    public init(view: View, mapper: @escaping Mapper) {
        self.view = view
        self.mapper = mapper
    }
    
    public func didStartLoading() {
        view.display(ResourceLoadingViewModel(isLoading: true))
        view.display(ResourceLoadingErrorViewModel(message: nil))
    }
    
    public func didFinishLoadingWithError() {
        view.display(ResourceLoadingViewModel(isLoading: false))
        view.display(ResourceLoadingErrorViewModel(message: "Invalid data"))
    }
    
    public func didFinishLoading(with resource: Resource) {
        view.display(ResourceLoadingViewModel(isLoading: false))
        view.display(mapper(resource))
    }
}
