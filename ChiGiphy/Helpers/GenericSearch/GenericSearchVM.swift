//
//  GenericSearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 18/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

class GenericSearchVM<T: Hashable> {
    
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
    
    private var nextPageRequestDisposable: Disposable? = nil
    
    // MARK: Init
    
    init() {
        performSearchOnQueryChange()
    }
    
    // MARK: Methods
    
    private func performSearchOnQueryChange() {
        searchQueryRelay
            .asObservable()
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(0.5, scheduler: MainScheduler.instance)
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
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
                // Dispose of old next page requests
                self.nextPageRequestDisposable?.dispose()
                // Recreate fetch next page subscription
                self.nextPageRequestDisposable = self.createFetchNextPageOnDemand()
                // Make sure listeners know about fetch finished state
                self.performingSearchRelay.accept(false)
                // Process fetch result
                if elements.isEmpty {
                    self.errorSubject.onNext(SearchError.notFound)
                } else {
                    self.contentRelay.accept(elements)
                }
            })
            .disposed(by: bag)
    }
    
    private func createFetchNextPageOnDemand() -> Disposable {
        return fetchNextPageRelay
            .asObservable()
            .distinctUntilChanged()
            .filter { $0 }
            .flatMapLatest { [unowned self] _ -> Observable<[T]> in
                return self.getNextPage().retry()
                    .catchError { [unowned self] error -> Observable<[T]> in
                        self.errorSubject.onNext(SearchError.underlyingError(error))
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { [unowned self] nextPageBatch in
                self.fetchNextPageRelay.accept(false)
                if !nextPageBatch.isEmpty {
                    // Append only unique items
                    let alreadyHaveSet = Set(self.contentRelay.value)
                    let newUnique = nextPageBatch.filter { !alreadyHaveSet.contains($0) }
                    self.contentRelay.accept(self.contentRelay.value + newUnique)
                }
            })
    }

    // MARK: Required subclass overrides
    
    func search(byTerm term: String) -> Observable<[T]> {
        fatalError("Override this function with your custom implementation")
    }
    
    func getNextPage() -> Observable<[T]> {
        fatalError("Override this function with your custom implementation")
    }
}
