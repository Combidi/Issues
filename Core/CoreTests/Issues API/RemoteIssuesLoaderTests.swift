//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class RemoteIssuesLoader {
    private let client: Client
    private let url: URL
    
    init(client: Client, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadIssues() {
        client.get(from: url)
    }
}

final class Client {
    var loadedURLs = [URL]()
    
    func get(from url: URL) {
        loadedURLs.append(url)
    }
}

class RemoteIssuesLoaderTests: XCTestCase {
    
    func test_loadIssues_requestsIssuesFromClient() {
        let url = URL(string: "https://a-url.com")!
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url)
        
        sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
}
