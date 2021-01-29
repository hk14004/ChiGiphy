//
//  CellVMs.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SearchingGiphyCellVM: Equatable, IdentifiableType {
    
    static func == (lhs: SearchingGiphyCellVM, rhs: SearchingGiphyCellVM) -> Bool {
        true
    }
    
    var identity: String {
        "\(Self.self)"
    }
}

class GiphyCellVM: Equatable, IdentifiableType {
    
    var identity: String {
        item.id
    }
    
    private let item: GiphyItem
    
    init(item: GiphyItem) {
        self.item = item
    }
    
    static func == (lhs: GiphyCellVM, rhs: GiphyCellVM) -> Bool {
        lhs.item == rhs.item
    }
}

class InitialGiphyCellVM: Equatable, IdentifiableType {
    
    var identity: String {
        "\(Self.self)"
    }
    
    static func == (lhs: InitialGiphyCellVM, rhs: InitialGiphyCellVM) -> Bool {
        true
    }
}

class NotFoundGiphyCellVM: Equatable {
    
    var identity: String {
        "\(Self.self)"
    }
    
    static func == (lhs: NotFoundGiphyCellVM, rhs: NotFoundGiphyCellVM) -> Bool {
        true
    }
}
