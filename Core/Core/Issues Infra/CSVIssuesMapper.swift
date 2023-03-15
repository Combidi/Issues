//
//  Created by Peter Combee on 01/09/2022.
//

import Foundation

public struct CSVIssuesMapper {    
    public enum Error: Swift.Error, Equatable {
        case invalidData
        case invalidHeaders
        case invalidComponentCount(components: [String])
        case invalidDateFormat(date: String)
    }
    
    private init() {}
    
    public static func map(data: Data, timeZone: TimeZone = .current) throws -> [Issue] {
        let dataString = try dataString(from: data)
        var lines = lines(from: dataString)
        try validateHeaders(lines: &lines)
        
        let issues: [Issue] = try lines.enumerated().map { index, line in
            try map(line: line, timeZone: timeZone)
        }

        return issues
    }
    
    private static func map(line: String, timeZone: TimeZone) throws -> Issue {
        let components = line.components(separatedBy: ",")
        
        guard components.count == 4 else { throw Error.invalidComponentCount(components: components) }
        
        return Issue(
            firstName: components[0],
            surname: components[1],
            submissionDate: try date(from: components[3], forTimeZone: timeZone),
            subject: components[2]
        )
    }
    
    private static func dataString(from data: Data) throws -> String {
        guard let dataString = String(data: data, encoding: .utf8), !dataString.isEmpty else { throw Error.invalidData }
        return dataString
    }
        
    private static func date(from string: String, forTimeZone timeZone: TimeZone) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = timeZone
        
        guard let date = formatter.date(from: string) else {
            throw Error.invalidDateFormat(date: string)
        }
        return date
    }
    
    private static func lines(from dataString: String) -> [String] {
        dataString
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }
    
    private static func validateHeaders(lines: inout [String]) throws {
        let validHeader = ["First name","Sur name","Subject","Date of submission"]
        guard lines.removeFirst().components(separatedBy: ",") == validHeader else {
            throw Error.invalidHeaders
        }
    }
}
