//
//  Created by Peter Combee on 16/10/2022.
//

import XCTest

final class StreamingFileReader {
    private let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func readNextLine() -> String {
        let data = try! Data(contentsOf: fileURL)
        let rangeOfDelimiter = data.range(of: "\n".data(using: .utf8)!)
        let rangeOfFirstLine = 0 ..< rangeOfDelimiter!.lowerBound
        let firstLine = String(data: data.subdata(in: rangeOfFirstLine), encoding: .utf8)
        return firstLine!
    }
}

class StreamingFileReaderTests: XCTestCase {
    
    func test_readNextLine_returnsFirstLine() {
        
        let testData = Data("first\nsecond\nthird\nfourth".utf8)
        let fileURL = testSpecificFileURL()
        let sut = StreamingFileReader(fileURL: fileURL)
        inject(testData: testData)
        
        let result = sut.readNextLine()
        
        XCTAssertEqual(result, "first")
        removeTestData()
    }
    
    // MARK: Helpers
    
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
