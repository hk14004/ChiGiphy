//
//  LoadingMoreCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import RxSwift
import RxCocoa
import RxDataSources

class LoadingMoreCellVM {}

extension LoadingMoreCellVM: Equatable {
    static func == (lhs: LoadingMoreCellVM, rhs: LoadingMoreCellVM) -> Bool {
        true
    }
}

extension LoadingMoreCellVM: IdentifiableType {
    var identity: String {
        "\(Self.self)"
    }
}
