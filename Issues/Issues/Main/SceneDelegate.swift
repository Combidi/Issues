//
//  Created by Peter Combee on 22/08/2022.
//

import UIKit
import Core

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        guard let url = Bundle.main.url(forResource: "issues", withExtension: "csv") else {
            assertionFailure("File `issuses.csv` not found")
            return
        }
        let loader = FileSystemIssueLoader(fileURL: url, mapper: { try CSVIssuesMapper.map($0) })
        
        let issues = IssuesUIComposer.compose(withLoader: { completion in
            loader.loadIssues { result in
                completion(result.map { Paginated(models: $0, loadMore: nil) })
            }
        })
        window?.rootViewController = UINavigationController(rootViewController: issues)
        window?.makeKeyAndVisible()
    }
}
