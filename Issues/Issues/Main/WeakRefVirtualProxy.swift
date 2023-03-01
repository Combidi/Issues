//
//  Created by Peter Combee on 22/02/2023.
//

final class WeakRefVirtualProxy<T: AnyObject> {
    private(set) weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}
