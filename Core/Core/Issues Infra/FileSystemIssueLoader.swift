//
//  Created by Peter Combee on 02/09/2022.
//

import Foundation

public final class FileSystemIssueLoader: IssuesLoader {
    private let fileURL: URL
    private let mapper: (Data) throws -> [Issue]
    
    public init(fileURL: URL, mapper: @escaping (Data) throws -> [Issue]) {
        self.fileURL = fileURL
        self.mapper = mapper
    }
    
    private let queue = DispatchQueue(label: "\(FileSystemIssueLoader.self)Queue", qos: .userInitiated)

    public func loadIssues(completion: @escaping Completion) {
        let fileURL = fileURL
        let mapper = mapper
        queue.sync {
            do {
                let data = try Data(contentsOf: fileURL)
                completion(.success(try mapper(data)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
