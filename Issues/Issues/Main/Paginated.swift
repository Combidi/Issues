//
//  Created by Peter Combee on 01/03/2023.
//

public struct Paginated<T> {
    public typealias LoadMoreResult = Result<Self, Error>
    public typealias LoadMoreCompletion = (LoadMoreResult) -> Void
    public typealias LoadMore = (@escaping LoadMoreCompletion) -> Void
    
    let models: [T]
    public let loadMore: LoadMore?

    public init(models: [T], loadMore: LoadMore?) {
        self.models = models
        self.loadMore = loadMore
    }
}
