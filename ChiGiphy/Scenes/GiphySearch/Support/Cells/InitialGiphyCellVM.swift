//
//  InitialGiphyCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class InitialGiphyCellVM {}

extension InitialGiphyCellVM: Equatable {
    static func == (lhs: InitialGiphyCellVM, rhs: InitialGiphyCellVM) -> Bool {
        true
    }
}

extension InitialGiphyCellVM: IdentifiableType {
    var identity: String {
        "\(Self.self)"
    }
}
