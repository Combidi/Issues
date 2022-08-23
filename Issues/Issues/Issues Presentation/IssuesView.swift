//
//  Created by Peter Combee on 23/08/2022.
//

protocol IssuesView: AnyObject {
    func present(issues: [IssueViewModel])
    func presentLoading(_ isLoading: Bool)
    func presentError(_ message: String?)
}
