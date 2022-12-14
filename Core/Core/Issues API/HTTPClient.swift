//
//  Created by Peter Combee on 23/10/2022.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    typealias Completion = (Result) -> Void
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
