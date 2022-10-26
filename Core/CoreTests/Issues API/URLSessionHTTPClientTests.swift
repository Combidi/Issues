//
//  Created by Peter Combee on 23/10/2022.
//

import XCTest

final class URLSessionHTTPClient {
    typealias Result = Swift.Result<(data: Data, response: HTTPURLResponse), Error>
    
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                if let error { throw error }
                if let data = data, let response = response as? HTTPURLResponse {
                    return (data, response)
                }
                throw UnexpectedValuesRepresentation()
            })
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromUrl_performsGETRequestWithURL() {
        let url = anyURL()
        let sut = makeSUT()
            
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
        let error = anyNSError()

        let receivedError = resultErrorFor((data: nil, response: nil, error: error)) as? NSError
        XCTAssertEqual(receivedError?.code, error.code)
        XCTAssertEqual(receivedError?.domain, error.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }
        
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        URLProtocolStub.stub(values: (data: data, response: response, error: nil))
        
        let receivedValues = resultValuesFor((data: data, response: response, error: nil))
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor((data: nil, response: response, error: nil))

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    // MARK: Helpers
    
    private func makeSUT() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut)
        return sut
    }
    
    private func resultErrorFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(values)
        
        switch result {
        case let .failure(error):
            return error
            
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
   }

    private func resultValuesFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values)
        
        switch result {
        case let .success(values):
            return values
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient.Result {
        let sut = makeSUT()

        values.map { URLProtocolStub.stub(values: $0) }

        let exp = expectation(description: "Wait for equest")
        var receivedResult: URLSessionHTTPClient.Result!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }

    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyData() -> Data {
        Data("any".utf8)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
}

// MARK: Helpers

private class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?
    }
    private static var stub: Stub?
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        stub = Stub(data: nil, response: nil, error: nil, requestObserver: observer)
    }
    
    static func stub(values: (data: Data?, response: URLResponse?, error: Error?)) {
        stub = Stub(data: values.data, response: values.response, error: values.error, requestObserver: nil)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
                
        stub.requestObserver?(request)
    }
    
    override func stopLoading() {}
}

private extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
