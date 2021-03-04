//
//  GiphyCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

enum GiphyCellVMState {
    case initial
    case downloading
    case downloaded(Data)
}

protocol GiphyCellVMProtocol {
    
    // MARK: Output
    
    var state: Observable<GiphyCellVMState> { get }
    var size: CGSize { get }
}

class GiphyCellVM: GiphyCellVMProtocol{
    
    // MARK: Output
    
    @VMProperty(.initial) var state: Observable<GiphyCellVMState>
    
    // MARK: Vars
    
    private let item: GiphyItem
    
    var size: CGSize {
        CGSize(width: Int(item.image.width) ?? 0, height: Int(item.image.height) ?? 0)
    }
    
    private let disposeBag = DisposeBag()
    
    private let service: GiphyServiceProtocol
    
    // MARK: Init
    
    init(item: GiphyItem, service: GiphyServiceProtocol = GiphyService()) {
        self.item = item
        self.service = service
        loadGif().bind(to: $state).disposed(by: disposeBag)
    }
    
    // MARK: Methods
    
    private func loadGif() -> Observable<GiphyCellVMState> {
        Observable<GiphyCellVMState>.create { [unowned self] (observer) -> Disposable in
            observer.onNext(.downloading)
            service.downloadGif(url: item.image.url)
                .retry(.delayed(maxCount: UInt.max, time: 3))
                .subscribe { (data) in
                    observer.onNext(.downloaded(data))
                }.disposed(by: disposeBag)
            
            return Disposables.create()
        }
    }
}

extension GiphyCellVM: IdentifiableType {
    var identity: String {
        item.id
    }
}

extension GiphyCellVM: Equatable {
    static func == (lhs: GiphyCellVM, rhs: GiphyCellVM) -> Bool {
        lhs.item == rhs.item
    }
}
