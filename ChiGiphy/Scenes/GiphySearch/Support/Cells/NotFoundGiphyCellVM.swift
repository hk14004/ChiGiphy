//
//  NotFoundGiphyCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import RxSwift
import RxCocoa
import RxDataSources

class NotFoundGiphyCellVM {}

extension NotFoundGiphyCellVM: Equatable {
    static func == (lhs: NotFoundGiphyCellVM, rhs: NotFoundGiphyCellVM) -> Bool {
        true
    }
}

extension NotFoundGiphyCellVM: IdentifiableType {
    var identity: String {
        "\(Self.self)"
    }
}
