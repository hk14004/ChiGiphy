//
//  Decodable+Extensions.swift
//  ChiGiphy
//
//  Created by Hardijs on 01/03/2021.
//

import Foundation

struct FailableDecodable<Element: Decodable>: Decodable {
    var element: Element?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        element = try? container.decode(Element.self)
    }
}
struct LossyDecodableArray<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: Decoder) throws {
        var elements = [Element?]()
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            let item = try container.decode(FailableDecodable<Element>.self).element
            elements.append(item)
        }
        self.elements = elements.compactMap { $0 }
    }
}
extension LossyDecodableArray: RandomAccessCollection {
    var startIndex: Int { return elements.startIndex }
    var endIndex: Int { return elements.endIndex }
    
    subscript(_ index: Int) -> Element {
        return elements[index]
    }
}
