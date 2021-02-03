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
    
    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    
    var isLoadingDriver: Driver<Bool> {
        loadingSubject.asDriver(onErrorJustReturn: true)
    }
    
    var isLoadingObserver: AnyObserver<Bool> {
        loadingSubject.asObserver()
    }
    
    private let disposeBag = DisposeBag()
    
    func loadGifData() -> Observable<Data> {
        loadingSubject.onNext(true)
        let downloadObservable = GiphyService.shared.downloadGif(url: item.image.url)
            .retry() //TOOD: Exp back off via RxSwiftExt?
            .share()
        downloadObservable.subscribe(onError: { error in
            print("cell error")
        }).disposed(by: disposeBag)
        return downloadObservable
    }
        
    deinit {
        print("VM DEINIT")
    }
    
    // MARK: TDD
    
    var identity: String {
        item.id
    }
    
    var size: CGSize {
        CGSize(width: Int(item.image.width) ?? 0, height: Int(item.image.height) ?? 0)
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

class LoadingMoreCellVM: Equatable {
    
    var identity: String {
        "\(Self.self)"
    }
    
    static func == (lhs: LoadingMoreCellVM, rhs: LoadingMoreCellVM) -> Bool {
        true
    }
}
