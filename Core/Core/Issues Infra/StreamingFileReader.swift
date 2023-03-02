//
//  Created by Peter Combee on 20/10/2022.
//

import Foundation

public final class StreamingFileReader {
    public enum Delimiter: String {
        case carriageReturn = "\r"
        case lineFeed = "\n"
        case endOfLine = "\r\n"
    }

    private let fileHandle: FileHandle
    private let delimiter: Data

    public init(fileURL: URL, delimiter: Delimiter) throws {
        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        self.delimiter = Data(delimiter.rawValue.utf8)
    }
    
    private let chunkSize: Int = 10
    private var buffer = Data()

    public func readNextLine() -> String? {
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

/// You can use this to determine if you reached the end of the file. This is needed to determine if you need to show a load more cell or not.
/// https://developer.apple.com/documentation/foundation/filehandle/1411463-availabledata

