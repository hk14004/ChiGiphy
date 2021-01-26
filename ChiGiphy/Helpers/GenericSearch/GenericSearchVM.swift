//
//  GenericSearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 18/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

class GenericSearchVM<T> {
    
    // MARK: Variables
    
    let searchQueryRelay = BehaviorRelay<String>(value: "")
        
    let errorSubject = PublishSubject<SearchError?>()
    
    var errorDriver: Driver<SearchError?> {
        return errorSubject
            .asDriver(onErrorJustReturn: SearchError.unknown)
    }

    let contentRelay = BehaviorRelay<[T]>(value: [])
    
    lazy var loadingObservable: Observable<Bool> = {
        Observable.combineLatest(performingSearchRelay, fetchNextPageRelay).map {
            return $0 || $1
        }
        .distinctUntilChanged()
        .share()
    }()
    
    let performingSearchRelay = BehaviorRelay<Bool>(value: false)
    
    var fetchNextPageRelay = BehaviorRelay<Bool>(value: false)
    
    private let bag = DisposeBag()
    
    // MARK: Init
    
    init() {
        performSearchOnQueryChange()
        fetchNextPageOnDemand()
    }
    
    // MARK: Methods
    
    private func performSearchOnQueryChange() {
        searchQueryRelay
            .asObservable()
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(0.5, scheduler: MainScheduler.instance)
            .flatMapLatest { [unowned self] term -> Observable<[T]> in
                self.errorSubject.onNext(nil)
                self.performingSearchRelay.accept(true)
                self.contentRelay.accept([])
                
                return self.search(byTerm: term).retry()
                    .catchError { [unowned self] error -> Observable<[T]> in
                        self.errorSubject.onNext(SearchError.underlyingError(error))
                        return Observable.empty()
                }
            }
            .subscribe(onNext: { [unowned self] elements in
                self.performingSearchRelay.accept(false)
                if elements.isEmpty {
                    self.errorSubject.onNext(SearchError.notFound)
                } else {
                    self.contentRelay.accept(elements)
                }
            })
            .disposed(by: bag)
    }
    
    private func fetchNextPageOnDemand() {
        fetchNextPageRelay
            .asObservable()
            .distinctUntilChanged()
            .filter { $0 }
            .flatMapLatest { [unowned self] bool -> Observable<[T]> in
                return self.getNextPage().retry()
                    .catchError { [unowned self] error -> Observable<[T]> in
                        self.errorSubject.onNext(SearchError.underlyingError(error))
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [unowned self] nextPageBatch in
                self.fetchNextPageRelay.accept(false)
                if !nextPageBatch.isEmpty {
                    self.contentRelay.accept(self.contentRelay.value + nextPageBatch)
                }
            })
            .disposed(by: bag)
    }

    // MARK: Required subclass overrides
    
    func search(byTerm term: String) -> Observable<[T]> {
        fatalError("Override this function with your custom implementation")
    }
    
    func getNextPage() -> Observable<[T]> {
        fatalError("Override this function with your custom implementation")
    }
}
