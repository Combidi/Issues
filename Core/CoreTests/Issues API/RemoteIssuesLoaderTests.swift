//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class RemoteIssuesLoader {
    struct InvalidDataError: Swift.Error {}
    
    private let client: Client
    private let url: URL
    
    init(client: Client, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadIssues() throws -> [String] {
        let result = try client.get(from: url)
        if result.isEmpty {
            throw InvalidDataError()
        } else {
            return []
        }
    }
}

final class Client {
    var loadedURLs = [URL]()
    var stub: Result<Data, Error> = .success(Data())
        
    func get(from url: URL) throws -> Data {
        loadedURLs.append(url)
        switch stub {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }
}

class RemoteIssuesLoaderTests: XCTestCase {
    
    func test_loadIssues_requestsIssuesFromClient() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        _ = try? sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url])
    }
    
    func test_loadIssuesTwice_requestsIssuesFromClientTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        _ = try? sut.loadIssues()
        _ = try? sut.loadIssues()
        
        XCTAssertEqual(client.loadedURLs, [url, url])
    }
    
    func test_loadIssues_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "any", code: 1)
        client.stub = .failure(clientError)
    
        XCTAssertThrowsError(try sut.loadIssues())
    }
    
    func test_loadIssues_deliverErrorOnEmptyData() {
        let (sut, client) = makeSUT()
        let emptyData = Data()
        client.stub = .success(emptyData)
    
        XCTAssertThrowsError(try sut.loadIssues())
    }

    func test_loadIssues_deliverEmptyListOnValidDataWithEmptyIssuesList() {
        let (sut, client) = makeSUT()
        let emptyListData = Data("{ issues: {} }".utf8)
        client.stub = .success(emptyListData)
    
        XCTAssertEqual(try sut.loadIssues(), [])
    }
    
    // MARK: Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteIssuesLoader, client: Client) {
        let client = Client()
        let sut = RemoteIssuesLoader(client: client, url: url)
        return (sut, client)
    }
}
