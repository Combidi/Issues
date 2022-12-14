//
//  Created by Peter Combee on 29/08/2022.
//

public protocol IssuesView {
    func present(issues: [IssueViewModel])
    func presentMessage(_ message: String?)
    func presentLoading(_ flag: Bool)
}
