//
//  IssuesViewModelMapperTests.swift
//  CoreTests
//
//  Created by Peter Combee on 22/02/2023.
//

import Core
import XCTest

final class IssuesViewModelMapperTests: XCTestCase {
    
    func test_map() {
        let locale = Locale(identifier: "en_US_POSIX")
        let sut = IssueViewModelMapper(locale: locale)
        let issues = [
            Issue(firstName: "Peter", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 662072400), subject: "Phone charger is missing"),
            Issue(firstName: "Luna", surname: "Combee", submissionDate: Date(timeIntervalSince1970: 720220087), subject: "My game controller is broken")
        ]
            
        let expectedViewModels = [
            IssueViewModel(name: "Peter Combee", submissionDate: "Dec 24, 1990", subject: "Phone charger is missing"),
            IssueViewModel(name: "Luna Combee", submissionDate: "Oct 27, 1992", subject: "My game controller is broken"),
        ]

        XCTAssertEqual(sut.map(issues: issues), expectedViewModels)
    }
}
