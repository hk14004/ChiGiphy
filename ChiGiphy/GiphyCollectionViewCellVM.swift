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
    
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    
    var isLoadingDriver: Driver<Bool> {
        loadingSubject.asDriver(onErrorJustReturn: true)
    }
    
    var isLoadingObserver: AnyObserver<Bool> {
        loadingSubject.asObserver()
    }
    
    private let gifItem: GiphyItem
    
    private let disposeBag = DisposeBag()
    
    func loadGifData() -> Observable<Data> {
        loadingSubject.onNext(true)
        let o = GiphyService.shared.downloadGif(url: gifItem.image.url).share()
        o.subscribe(onError: { error in
            print("cell error")
        }).disposed(by: disposeBag)
        return o
    }
    
    init(gifItem: GiphyItem) {
        self.gifItem = gifItem
    }
    
    deinit {
        print("VM DEINIT")
    }
}
