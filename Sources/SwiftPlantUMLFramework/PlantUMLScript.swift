import Foundation
import SwiftUI

/// Swift type representing a PlantUML script (@startuml ... @enduml)
public struct PlantUMLScript {
    /// textual representation of the script (@startuml ... @enduml)
    public private(set) var text: String = ""

    /// public private(set) var configuration: PlantUMLConfiguration = .default
    private var context: PlantUMLContext

    /// default initializer
    internal init(items: [SyntaxStructure], configuration: Configuration = .default) {
        context = PlantUMLContext(configuration: configuration)

        let methodStart = Date()

        text = "@startuml"
        if let theme = configuration.theme {
            text.appendAsNewLine("!theme \(theme.rawValue)")
        }
        if let includeRemoteURL = configuration.includeRemoteURL {
            text.appendAsNewLine("!include \(includeRemoteURL)")
        }
        text.appendAsNewLine(defaultStyling)
        if let title = configuration.title {
            text.appendAsNewLine("title \(title)")
        }

        let newLine = "\n"
        var mainContent = newLine

        var adjustedItems = items

        if context.configuration.elements.showNestedTypes {
            adjustedItems = adjustedItems.populateNestedTypes()
        }

        adjustedItems = adjustedItems.orderedByProtocolsFirstExtensionsLast()

        if context.configuration.shallExtensionsBeMerged {
            adjustedItems = adjustedItems.mergeExtensions(mergedMemberIndicator: context.configuration.elements.mergedExtensionMemberIndicator)
        }

        if let rectangles = configuration.rectangles {
            var namesAndLines = [(name: String, line: String)]()
            for (index, element) in adjustedItems.enumerated() {
                if let text = processStructureItem(item: element, index: index) {
                    namesAndLines.append((element.name!, text))
                }
            }
            let rectsText = rectangles.getRectanglesLine(namesAndLines: &namesAndLines)
            if !rectsText.isEmpty {
                mainContent.appendAsNewLine(rectsText)
            }
            for namesAndLine in namesAndLines {
                mainContent.appendAsNewLine(namesAndLine.line)
            }
        } else {
            for (index, element) in adjustedItems.enumerated() {
                if let text = processStructureItem(item: element, index: index) {
                    mainContent.appendAsNewLine(text)
                }
            }
        }

        context.collectNestedTypeConnections(items: adjustedItems)

        let definitions = mainContent + newLine + context.connections.joined(separator: newLine) + newLine + context.extnConnections.joined(separator: newLine)

        text.appendAsNewLine(definitions)
        text.appendAsNewLine("@enduml")

        Logger.shared.debug("PlantUML script created in \(Date().timeIntervalSince(methodStart)) seconds")
    }

    /**
      encodes diagram text description according to PlantUML.  See https://plantuml.com/en/text-encoding for more information.

       1. Encoded in UTF-8
       2. Compressed using Deflate algorithm
       3. Reencoded in ASCII using a transformation *close* to base64

     - Returns: encoded diagram text description
     */
    public func encodeText() -> String {
        PlantUMLText(rawValue: text).encodedValue
    }

    /// default styling block to hide empty members and disable shadowing
    internal var defaultStyling: String {
        let hideShowCommands: [String] = context.configuration.hideShowCommands ?? ["hide empty members"]
        let skinparamCommands: [String] = context.configuration.skinparamCommands ?? ["skinparam shadowing false"]

        if hideShowCommands.isEmpty, skinparamCommands.isEmpty {
            return ""
        } else {
            return """
            ' STYLE START
            \(hideShowCommands.joined(separator: "\n"))
            \(skinparamCommands.joined(separator: "\n"))
            ' STYLE END
            """
        }
    }

    private func getRectLine(
        rects: [RectangleOptions],
        namesAndLines: inout [(name: String, line: String)]
    ) -> String {
        let spacing = "  "
        var rectanglesText = ""
        for rectangle in rects {
            rectanglesText.appendAsNewLine("rectangle \(rectangle.name) {")
            if let insideRects = rectangle.rectangles {
                let insideRectsText = getRectLine(rects: insideRects, namesAndLines: &namesAndLines)
                if !insideRectsText.isEmpty {
                    let valueLine = spacing + insideRectsText.replacingOccurrences(of: "\n", with: "\n"+spacing)
                    rectanglesText.appendAsNewLine(valueLine)
                }
            }
            if let rectValues = rectangle.values {
                for namesAndLine in namesAndLines {
                    if rectValues.contains(namesAndLine.name) {
                        let valueLine = spacing + namesAndLine.line.replacingOccurrences(of: "\n", with: "\n"+spacing)
                        if let index = namesAndLines.firstIndex(where: { $0.name == namesAndLine.name && $0.line == namesAndLine.line }) {
                            namesAndLines.remove(at: index)
                            rectanglesText.appendAsNewLine(valueLine)
                        }
                    }
                }
            }
            rectanglesText.appendAsNewLine("}")
        }
        return rectanglesText
    }

    mutating func processStructureItem(item: SyntaxStructure, index _: Int) -> String? {
        let processableKinds: [ElementKind] = [.class, .struct, .extension, .enum, .protocol]
        guard let elementKind = item.kind else { return nil }
        guard processableKinds.contains(elementKind) else { return nil }
        return item.plantuml(context: context) ?? nil
    }
}
