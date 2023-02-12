//
//  Created by Peter Combee on 24/08/2022.
//

import XCTest
import Issues
import Core

final class IssuesSnapshotTests: XCTestCase {
    
    func test_issues() {
        let sut = IssuesViewController()
        
        sut.display(cellControllers: issues())
    
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light)), named: "ISSUES_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .dark)), named: "ISSUES_WITH_CONTENT_dark")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light, contentSize: .extraExtraExtraLarge)), named: "ISSUES_WITH_CONTENT_light_extraExtraExtraLarge")
    }

    func test_issuesWithLoadMore() {
        let sut = IssuesViewController()
        
        sut.display(cellControllers: issuesWithLoadMore())
    
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light)), named: "ISSUES_WITH_LOAD_MORE_light")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .dark)), named: "ISSUES_WITH_LOAD_MORE_dark")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light, contentSize: .extraExtraExtraLarge)), named: "ISSUES_WITH_LOAD_MORE_light_extraExtraExtraLarge")
    }
    
    func test_loading() {
        let sut = IssuesViewController()
        
        sut.display(isLoading: true)
    
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light)), named: "ISSUES_LOADING_light")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .dark)), named: "ISSUES_LOADING_dark")
    }

    func test_withError() {
        let sut = IssuesViewController()
        
        sut.display(message: "A message")
        
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light)), named: "ISSUES_WITH_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .dark)), named: "ISSUES_WITH_ERROR_dark")
        assert(snapshot: sut.snapshot(for: .iPhone14(style: .light, contentSize: .extraSmall)), named: "ISSUES_WITH_ERROR_light_extraSmall")
    }
    
    // MARK: Helpers
    
    private func issues() -> [UITableViewDataSource] {
        [
            IssueViewModel(
                name: "a name",
                submissionDate: "24-12-1990",
                subject: "a subject"
            ),
            IssueViewModel(
                name: "a realy realy realy realy long name",
                submissionDate: "23-11-1991",
                subject: "a multi-line\nsubject"
            )
        ].map(IssueCellController.init(issue:))
    }
    
    private func issuesWithLoadMore() -> [UITableViewDataSource] {
        issues() + [LoadMoreCellController()]
    }
}

extension XCTestCase {
    
    func assert(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail("Failed to load stored snapshot at URL: \(snapshot). Use the `record` method to store a snapshot before asserting.", file: file, line: line)
            return
        }
        
        if snapshotData != storedSnapshotData {
            let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(snapshotURL.lastPathComponent)
            
            try? snapshotData?.write(to: temporarySnapshotURL)
            
            XCTFail("New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL), Stored snapshot URL: \(snapshotURL)", file: file, line: line)
        }
    }
    
    func record(snapshot: UIImage, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            try snapshotData?.write(to: snapshotURL)
            XCTFail("Record succeeded - use `assert` to compare the snapshot from now on.", file: file, line: line)
        } catch {
            XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
    
    private func makeSnapshotURL(named name: String, file: StaticString) -> URL {
        return URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots")
            .appendingPathComponent("\(name).png")
    }
    
    private func makeSnapshotData(for snapshot: UIImage, file: StaticString, line: UInt) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail("Failed to generate PNG data representation from snapshot", file: file, line: line)
            return nil
        }
        
        return data
    }
}

extension UIViewController {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        return SnapshotWindow(configuration: configuration, root: self).snapshot()
    }
}

struct SnapshotConfiguration {
    let size: CGSize
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection
    
    static func iPhone14(style: UIUserInterfaceStyle, contentSize: UIContentSizeCategory = .medium) -> SnapshotConfiguration {
        return SnapshotConfiguration(
            size: CGSize(width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
            layoutMargins: UIEdgeInsets(top: 55, left: 8, bottom: 42, right: 8),
            traitCollection: UITraitCollection(traitsFrom: [
                .init(forceTouchCapability: .unavailable),
                .init(layoutDirection: .leftToRight),
                .init(preferredContentSizeCategory: contentSize),
                .init(userInterfaceIdiom: .phone),
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular),
                .init(displayScale: 3),
                .init(accessibilityContrast: .normal),
                .init(displayGamut: .P3),
                .init(userInterfaceStyle: style)
            ]))
    }

}

private final class SnapshotWindow: UIWindow {
    private var configuration: SnapshotConfiguration = .iPhone14(style: .light)

    convenience init(configuration: SnapshotConfiguration, root: UIViewController) {
        self.init(frame: CGRect(origin: .zero, size: configuration.size))
        self.configuration = configuration
        self.layoutMargins = configuration.layoutMargins
        self.rootViewController = root
        self.isHidden = false
        root.view.layoutMargins = configuration.layoutMargins
    }

    override var safeAreaInsets: UIEdgeInsets {
        return configuration.safeAreaInsets
    }

    override var traitCollection: UITraitCollection {
        return UITraitCollection(traitsFrom: [super.traitCollection, configuration.traitCollection])
    }

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: .init(for: traitCollection))
        return renderer.image { action in
            layer.render(in: action.cgContext)
        }
    }
}
