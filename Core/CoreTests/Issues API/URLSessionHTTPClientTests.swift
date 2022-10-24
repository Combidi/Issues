//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (Error?) -> Void) {
        session.dataTask(with: url) { _, _, error in
            completion(error)
        }.resume()
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
        
        sut.get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://a-url.com")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        let error = NSError(domain: "any", code: 1)
        URLProtocolStub.stub(error: error)
        
        let exp = expectation(description: "Wait for equest")
        var receivedError: NSError?
        sut.get(from: url) { error in
            receivedError = error as? NSError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError?.domain, error.domain)
        XCTAssertEqual(receivedError?.code, error.code)
    }
}

private class URLProtocolStub: URLProtocol {
    private struct Stub {
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?
    }
    private static var stub: Stub?
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = Stub(error: nil, requestObserver: observer)
    }
    
    static func stub(error: Error?) {
        stub = Stub(error: error, requestObserver: nil)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
                
        URLProtocolStub.stub?.requestObserver?(request)
    }
    
    override func stopLoading() {}
}
