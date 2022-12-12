//
//  Created by Peter Combee on 08/11/2022.
//

import UIKit
import SwiftUI
import Core

public struct SwiftUIIssuesUIComposer {
    private init() {}
    
    public static func compose(
        withLoader loader: IssuesLoader,
        locale: Locale = .current
    ) -> IssuesListView {
        let model = IssuesListViewModel()
        let view = IssuesListView(model: model)
        let presenter = IssuesPresenter(
            loader: loader,
            view: MainThreadDispatchingIssueViewDecorator(decoratee: WeakRefVirtualProxy(model)),
            locale: locale
        )
        model.loadIssues = presenter.loadIssues
        return view
    }
}

private final class MainThreadDispatchingIssueViewDecorator: IssuesView {
    private let decoratee: IssuesView

    init(decoratee: IssuesView) {
        self.decoratee = decoratee
    }

    func present(issues: [IssueViewModel]) {
        dispatch {
            self.decoratee.present(issues: issues)
        }
    }

    func presentMessage(_ message: String?) {
        dispatch {
            self.decoratee.presentMessage(message)
        }
    }

    func presentLoading(_ flag: Bool) {
        dispatch {
            self.decoratee.presentLoading(flag)
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

private final class WeakRefVirtualProxy<T: AnyObject> {
    private(set) weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: IssuesView where T: IssuesView {
    func present(issues: [IssueViewModel]) {
        object?.present(issues: issues)
    }
    
    func presentLoading(_ isLoading: Bool) {
        object?.presentLoading(isLoading)
    }
    
    func presentMessage(_ message: String?) {
        object?.presentMessage(message)
    }
}
