//
//  Created by Peter Combee on 24/08/2022.
//

import SwiftUI

struct ContentView: View {
        
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: IssuesView(filename: "exampls.cvs")) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Local")
                    }
                    .foregroundColor(.primary)
                }
                NavigationLink(destination: IssuesView(filename: "http://example.issues.com")) {
                    HStack {
                        Image(systemName: "network")
                        Text("From API")
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Issues")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.grouped)
        }
    }
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
                        Text(issue.date)
                            .foregroundColor(.secondary)
                    }
                    Text(issue.message)
                }
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.vertical, 10)
            }
        }
        .listStyle(.grouped)
        .navigationTitle(filename)
    }
        
    private let sampleIssues = [
        Issue(
            firstName: "Peter",
            surname: "Combee",
            message: "TV does not work anymore",
            date: "24 dec"
        ),
        Issue(
            firstName: "Luna",
            surname: "Combee",
            message: "Dropped my phone",
            date: "03 apr"
        ),
        Issue(
            firstName: "Anke",
            surname: "Combee",
            message: "Crashed my car",
            date: "02 jan"
        )
    ]
}

enum Status: String {
    case new
    case pending
    case closed
}

struct Issue {
    let firstName: String
    let surname: String
    let message: String
    let date: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
