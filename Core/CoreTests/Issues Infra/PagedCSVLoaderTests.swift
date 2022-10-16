//
//  Created by Peter Combee on 16/10/2022.
//

import XCTest

final class StreamingFileReader {
    private let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func readNextLine() throws -> String? {
        let data = try Data(contentsOf: fileURL)
        if data.isEmpty { return nil }
        let rangeOfDelimiter = data.range(of: "\n".data(using: .utf8)!)
        let rangeOfFirstLine = 0 ..< rangeOfDelimiter!.lowerBound
        let firstLine = String(data: data.subdata(in: rangeOfFirstLine), encoding: .utf8)
        return firstLine!
    }
}

class StreamingFileReaderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        removeTestData()
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeTestData()
    }
    
    func test_readNextLine_deliverErrorOnMissingFile() {
        XCTAssertThrowsError(try makeSUT().readNextLine())
    }
    
    func test_readNextLine_deliversNilOnEmptyData() {
        let emptyData = Data()
        inject(testData: emptyData)
        
        XCTAssertNil(try makeSUT().readNextLine())
    }
    
    func test_readNextLine_returnsFirstLine() throws {
        let testData = Data("first\nsecond\nthird\nfourth".utf8)
        let sut = makeSUT()
        inject(testData: testData)
        
        let result = try sut.readNextLine()
        
        XCTAssertEqual(result, "first")
    }
    
    // MARK: Helpers
    
    private func makeSUT() -> StreamingFileReader {
        let fileURL = testSpecificFileURL()
        let sut = StreamingFileReader(fileURL: fileURL)
        return sut
    }
    
    private func testSpecificFileURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).txt")
    }
    
    private func inject(testData: Data) {
        try? testData.write(to: testSpecificFileURL())
    }
    
    private func removeTestData() {
        try? FileManager.default.removeItem(at: testSpecificFileURL())
    }
}
