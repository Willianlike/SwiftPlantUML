//
//  RectangleOptions.swift
//  
//
//  Created by Vilian Iaumbaev on 11/01/2023.
//

import Foundation

public class RectangleOptions: Codable {
    public var name: String
    public var values: [String]?
    public var rectangles: [RectangleOptions]?
    public init(name: String, values: [String]?, rectangles: [RectangleOptions]?) {
        self.name = name
        self.values = values
        self.rectangles = rectangles
    }
}


extension Array where Element == RectangleOptions {
    func getRectanglesLine(namesAndLines: inout [(name: String, line: String)]) -> String {
        let spacing = "  "
        var rectanglesText = ""
        for rectangle in self {
            rectanglesText.appendAsNewLine("rectangle \"\(rectangle.name)\" {")
            if let insideRects = rectangle.rectangles {
                let insideRectsText = insideRects.getRectanglesLine(namesAndLines: &namesAndLines)
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
}
