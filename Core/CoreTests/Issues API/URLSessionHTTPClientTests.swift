//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromUrl_performsGETRequestWithURL() {
        
        let url = URL(string: "http://a-url.com")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for equest")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        sut.get(from: url)
        
        wait(for: [exp], timeout: 1.0)
    }
}

private class URLProtocolStub: URLProtocol {
    private static var stub: ((URLRequest) -> Void)?
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = observer
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        URLProtocolStub.stub?(request)
    }
}
