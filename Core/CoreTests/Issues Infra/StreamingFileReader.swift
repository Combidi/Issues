//
//  Created by Peter Combee on 16/10/2022.
//

import XCTest

final class StreamingFileReader {
    enum Delimiter: String {
        case carriageReturn = "\r"
        case lineFeed = "\n"
        case endOfLine = "\r\n"
    }

    private let fileHandle: FileHandle
    private let delimiter: Data

    init(fileURL: URL, delimiter: Delimiter) throws {
        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        self.delimiter = Data(delimiter.rawValue.utf8)
    }
    
    private let chunkSize: Int = 10
    private var buffer = Data()

    func readNextLine() -> String? {
        repeat {
            if let rangeOfDelimiter = buffer.range(of: delimiter, in: buffer.startIndex..<buffer.endIndex) {
                let dataBeforeDelimiter = buffer.subdata(in: buffer.startIndex..<rangeOfDelimiter.lowerBound)
                let line = String(data: dataBeforeDelimiter, encoding: .utf8)
                buffer.replaceSubrange(buffer.startIndex..<rangeOfDelimiter.upperBound, with: [])
                return line
            } else {
                let nextChunk = fileHandle.readData(ofLength: chunkSize)
                if nextChunk.count == 0 {
                    defer { buffer.count = 0 }
                    return (buffer.count > 0) ? String(data: buffer, encoding: .utf8) : nil
                }
                buffer.append(nextChunk)
            }
        } while true
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
    
    func test_throwsOnMissingFile_deliverErrorOnMissingFile() {
        XCTAssertThrowsError(try StreamingFileReader(fileURL: testSpecificFileURL(), delimiter: .lineFeed))
    }
    
    func test_readNextLine_deliversNilOnEmptyData() {
        let emptyData = Data()
        inject(testData: emptyData)
        
        XCTAssertNil(makeSUT().readNextLine())
    }

    func test_readNextLine_returnsFirstLine() throws {
        let testData = Data("first\nsecond\nthird\nfourth".utf8)
        inject(testData: testData)
        let sut = makeSUT()
        
        let result = sut.readNextLine()
        
        XCTAssertEqual(result, "first")
    }
    
    func test_readNextLine_worksWithAllNewLineCharacters() throws {
        let delimiters: [StreamingFileReader.Delimiter] = [.carriageReturn, .lineFeed, .endOfLine]
                
        delimiters.forEach { delimiter in
            let testData = Data(["first", "second"].joined(separator: delimiter.rawValue).utf8)
            inject(testData: testData)
            let sut = makeSUT(delimiter: delimiter)

            let result = sut.readNextLine()

            XCTAssertEqual(result, "first")
        }
    }
    
    func test_readNextLine_returnsNewLineUntilReachingEndOfFile() throws {
        let testData = Data("first\nsecond\nthird\nfourth".utf8)
        inject(testData: testData)
        let sut = makeSUT()
        
        var result = [String]()
        while let next = sut.readNextLine() {
            result.append(next)
        }

        XCTAssertEqual(result, ["first", "second", "third", "fourth"])
    }
    
    // MARK: Helpers
    
    private func makeSUT(delimiter: StreamingFileReader.Delimiter = .lineFeed) -> StreamingFileReader {
        let fileURL = testSpecificFileURL()
        let sut = try! StreamingFileReader(fileURL: fileURL, delimiter: delimiter)
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
