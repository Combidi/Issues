//
//  Created by Peter Combee on 29/08/2022.
//

public protocol IssuesLoadingView {
    func presentLoading(_ flag: Bool)
}

public protocol IssuesView {
    func present(issues: [IssueViewModel])
}
