@testable import SwiftPlantUMLFramework
import XCTest

struct MockPlantUMLPresenter: PlantUMLPresenting {
    func present(script _: PlantUMLScript, completionHandler: @escaping () -> Void) {
        XCTAssertNotNil("Presenter called")
        completionHandler()
    }
}

final class ClassDiagramGeneratorTests: XCTestCase {
    func testNofiles() {
        let generator = ClassDiagramGenerator()
        generator.generate(for: [], presentedBy: MockPlantUMLPresenter())
    }

    func testSingleFile() {
        let generator = ClassDiagramGenerator()
        generator.generate(for: ["./Tests/SwiftPlantUMLFrameworkTests/TestData/demo.txt"], presentedBy: MockPlantUMLPresenter())
    }

    func testDotAlias() {
        let generator = ClassDiagramGenerator()
        generator.generate(for: ["."], presentedBy: MockPlantUMLPresenter())
    }
}