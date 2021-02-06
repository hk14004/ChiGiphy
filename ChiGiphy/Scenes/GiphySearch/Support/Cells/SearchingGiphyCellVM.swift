//
//  SearchingGiphyCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import RxSwift
import RxCocoa
import RxDataSources

// Currently we don't need anything really
class SearchingGiphyCellVM {}

extension SearchingGiphyCellVM: Equatable {
    static func == (lhs: SearchingGiphyCellVM, rhs: SearchingGiphyCellVM) -> Bool {
        true
    }
}

extension SearchingGiphyCellVM: IdentifiableType {
    var identity: String {
        "\(Self.self)"
    }
}
