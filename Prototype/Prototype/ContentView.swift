//
//  Created by Peter Combee on 24/08/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var sheetPresented = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sampleFiles, id: \.self) { file in
                    NavigationLink(destination: IssuesView(filename: file)) {
                        Text(file)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbar {
                Button(action: { sheetPresented = true }) {
                    Text("Add")
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
            
            .sheet(isPresented: $sheetPresented) {
                NavigationView {
                    Text("Document picker")
                        .navigationTitle("Files")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private let sampleFiles = ["exampls.cvs", "another.csv", "random.scv"]
}

struct IssuesView: View {
    
    let filename: String
    
    var body: some View {
        List {
            ForEach(sampleIssues, id: \.firstName) { issue in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(issue.firstName + " " + issue.surname).font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(issue.birthDate)
                            .foregroundColor(.secondary)
                    }
                    Text("Issues: " + issue.issueCount)
                        .font(.subheadline)
                    
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle(filename)
    }
    
    private let sampleIssues = [
        Issue(firstName: "Peter", surname: "Combee", issueCount: "12", birthDate: "24 dec. 1990"),
        Issue(firstName: "Luna", surname: "Combee", issueCount: "1", birthDate: "2 dec. 2010")
    ]
}

struct Issue {
    let firstName: String
    let surname: String
    let issueCount: String
    let birthDate: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
