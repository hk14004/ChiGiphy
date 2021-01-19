//
//  GiphyCollectionViewCellVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 19/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

class GiphyCollectionViewCellVM {
    
    // outputs
    private let loadingRelay = BehaviorSubject<Bool>(value: false)
    var isLoading: Driver<Bool> {
        loadingRelay.asDriver(onErrorJustReturn: true)
    }
    
    var preparingForAnimation: AnyObserver<Bool> {
        loadingRelay.asObserver()
    }
    
    private let gifItem: GiphyItem
    
    private let disposeBag = DisposeBag()
    
    let gifDataSubject = PublishSubject<Data>()
    
    func download() {
        loadingRelay.onNext(true)
        GiphyService.shared.downloadGif(url: gifItem.image.url).subscribe { (gifData) in
            self.gifDataSubject.onNext(gifData)
        } onError: { (error) in
            print("CELL ERROR", error.localizedDescription)
        } onCompleted: {
            print("Completed")
        } onDisposed: {
            print("Disposed")
        }.disposed(by: disposeBag)
    }
    
    init(gifItem: GiphyItem) {
        self.gifItem = gifItem
    }
    
    deinit {
        print("VM DEINIT")
    }
}
