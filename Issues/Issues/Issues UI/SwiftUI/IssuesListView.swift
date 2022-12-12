//
//  IssuesListView.swift
//  Issues
//
//  Created by Peter Combee on 08/11/2022.
//

import SwiftUI
import Core

public final class IssuesListViewModel: ObservableObject, IssuesView {
    @Published private(set) var issues: [IssueViewModel] = []
    @Published private(set) var isLoading = true
    @Published private(set) var message: String?
    
    var loadIssues: () -> Void = {}
        
    public func present(issues: [IssueViewModel]) {
        self.issues = issues
    }
    
    public func presentMessage(_ message: String?) {
        self.message = message
    }
    
    public func presentLoading(_ flag: Bool) {
        self.isLoading = flag
    }
}

public struct IssuesListView: View {
    @StateObject public var model: IssuesListViewModel
    
    public var body: some View {
        if model.isLoading {
            ProgressView()
                .onAppear(perform: model.loadIssues)
        } else if let message = model.message {
            Text(message)
        } else {
            List(model.issues, id: \.name) { model in
                VStack {
                    Text(model.name)
                    Text(model.subject)
                    Text(model.submissionDate)
                }
            }
        }
    }
}
