//
//  Created by Peter Combee on 01/09/2022.
//

import Foundation

public struct CSVIssuesMapper {
    private typealias Column = [String]
    
    public enum Error: Swift.Error, Equatable {
        case invalidData
        case invalidHeaders
        case invalidColumnSize(columnIndex: Int)
        case nonIntConvertable(columnIndex: Int, elementIndex: Int)
        case invalidDateFormat(columnIndex: Int, elementIndex: Int)
    }
    
    private init() {}
    
    public static func map(_ data: Data, timeZone: TimeZone = .current) throws -> [Issue] {
        let dataString = try dataString(from: data)
        var columns = columns(from: dataString)
        try validateHeaders(colums: &columns)
        
        let issues: [Issue] = try columns.enumerated().map { index, column in
            try validateColumnSize(column: column, atIndex: index)
            
            return Issue(
                firstName: column[0],
                surname: column[1],
                amountOfIssues: try int(from: column[2], columnIndex: index, elementIndex: 2),
                birthDate: try date(from: column[3], forTimeZone: timeZone, columnIndex: index, elementIndex: 3)
            )
        }

        return issues
    }

    private static func dataString(from data: Data) throws -> String {
        guard let dataString = String(data: data, encoding: .utf8), !dataString.isEmpty else { throw Error.invalidData }
        return dataString
    }
    
    private static func int(from string: String, columnIndex: Int, elementIndex: Int) throws -> Int {
        guard let intValue = Int(string) else { throw Error.nonIntConvertable(columnIndex: columnIndex, elementIndex: elementIndex) }
        return intValue
    }
    
    private static func date(from string: String, forTimeZone timeZone: TimeZone, columnIndex: Int, elementIndex: Int) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = timeZone
        
        guard let date = formatter.date(from: string) else {
            throw Error.invalidDateFormat(columnIndex: columnIndex, elementIndex: elementIndex)
        }
        return date
    }
    
    private static func columns(from dataString: String) -> [Column] {
        dataString
            .replacingOccurrences(of: "\"", with: "")
            .split(separator: "\n")
            .map { $0.split(separator: ",").map(String.init) }
    }
    
    private static func validateHeaders(colums: inout [Column]) throws {
        guard colums.removeFirst() == ["First name", "Sur name", "Issue count", "Date of birth"] else {
            throw Error.invalidHeaders
        }
    }
    
    private static func validateColumnSize(column: Column, atIndex index: Int) throws {
        guard column.count == 4 else { throw Error.invalidColumnSize(columnIndex: index) }
    }
}
