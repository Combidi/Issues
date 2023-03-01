//
//  Created by Peter Combee on 22/02/2023.
//

public protocol ResourceView {
    associatedtype ResourceViewModel
    
    func display(_ viewModel: ResourceViewModel)
}
