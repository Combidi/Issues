//
//  Created by Peter Combee on 15/03/2023.
//

public protocol StreamingReader {
    func nextLine() -> String?
}

public final class BatchedFileSystemIssueLoader: IssuesLoader {
    public typealias Mapper = (String) throws -> Issue
    
    private let streamingReader: StreamingReader
    private let batchSize: Int
    private let mapper: Mapper
    
    public init(streamingReader: StreamingReader, batchSize: Int, mapper: @escaping Mapper) {
        self.streamingReader = streamingReader
        self.batchSize = batchSize
        self.mapper = mapper
    }
    
    public func loadIssues(completion: @escaping Completion) {
        var issues = [Issue]()
        for _ in 0..<batchSize {
            guard let nextLine = streamingReader.nextLine() else {
                return completion(.success(issues))
            }
            do {
                let issue = try mapper(nextLine)
                issues.append(issue)
            } catch {
                return completion(.failure(error))
            }
        }
        completion(.success(issues))
    }
}
