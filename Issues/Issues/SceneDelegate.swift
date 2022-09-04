//
//  Created by Peter Combee on 22/08/2022.
//

import UIKit
import Core

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private lazy var navigationController = UINavigationController(
        rootViewController: IssuesViewController()
    )

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let url = Bundle.main.url(forResource: "issues", withExtension: "csv")!
        let loader = LocalIssueLoader(fileURL: url, mapper: { try CSVIssuesMapper.map($0) })
        let issues = IssuesUIComposer.compose(withLoader: loader)
        window?.rootViewController = UINavigationController(rootViewController: issues)
        window?.makeKeyAndVisible()
    }
}
