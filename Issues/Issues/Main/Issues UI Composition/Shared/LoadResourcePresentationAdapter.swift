//
//  LoadResourcePresentationAdapter.swift
//  Issues
//
//  Created by Peter Combee on 10/05/2023.
//

import Core
import Foundation

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    typealias LoadCompletion = (Result<Resource, Error>) -> Void
    typealias Load = (@escaping LoadCompletion) -> Void
    
    private let load: Load
    var presenter: LoadResourcePresenter<Resource, View>!
    
    init(load: @escaping Load) {
        self.load = load
    }
    
    private var isLoading = false
    
    func loadResource() {
        guard !isLoading else { return }
        presenter.didStartLoading()
        isLoading = true
        load { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            self.dispatch { [weak self] in
                self?.present(result: result)
            }
        }
    }
    
    private func present(result: Result<Resource, Error>) {
        switch result {
        case .success(let issues):
            presenter.didFinishLoading(with: issues)
            
        case .failure:
            presenter.didFinishLoadingWithError()
        }
    }
    
    private func dispatch(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
}
