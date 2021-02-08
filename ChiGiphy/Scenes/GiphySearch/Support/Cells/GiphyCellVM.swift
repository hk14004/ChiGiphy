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

class GiphyCellVM {
    
    // MARK: Vars
    
    let item: GiphyItem
    
    lazy var stateRelay: BehaviorRelay<GiphyCellVMState> = {
        let relay = BehaviorRelay<GiphyCellVMState>(value: .initial)
        loadGif().bind(to: relay).disposed(by: disposeBag)
        
        return relay
    }()
    
    private let disposeBag = DisposeBag()
    
    var size: CGSize {
        CGSize(width: Int(item.image.width) ?? 0, height: Int(item.image.height) ?? 0)
    }
    
    // MARK: Init
    
    init(item: GiphyItem, service: GiphyServiceProtocol = GiphyService()) {
        self.item = item
    }
    
    // MARK: Methods
    
    private func loadGif() -> Observable<GiphyCellVMState> {
        Observable<GiphyCellVMState>.create { [unowned self] (observer) -> Disposable in
            observer.onNext(.downloading)
            GiphyService.shared.downloadGif(url: item.image.url)
                .retry(.delayed(maxCount: UInt.max, time: 3))
                .share()
                .subscribe { (data) in
                    observer.onNext(.downloaded(data))
                } onError: { (error) in
                    print("Cell error")
                } onCompleted: {
                    print("Cell completed")
                } onDisposed: {
                    print("Cell disposed")
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
