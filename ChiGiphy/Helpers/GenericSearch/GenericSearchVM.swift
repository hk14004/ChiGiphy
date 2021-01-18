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
    // inputs
    private let searchSubject = PublishSubject<String>()
    var searchObserver: AnyObserver<String> {
        return searchSubject.asObserver()
    }
    
    private(set) var lastQuery: String = ""
     
    // outputs
    let loadingSubject = PublishSubject<Bool>()
    var isLoading: Driver<Bool> {
        return loadingSubject
            .asDriver(onErrorJustReturn: false)
    }

    let errorSubject = PublishSubject<SearchError?>()
    var error: Driver<SearchError?> {
        return errorSubject
            .asDriver(onErrorJustReturn: SearchError.unkowned)
    }

    let contentRelay = BehaviorRelay<[T]>(value: [])
    var content: Driver<[T]> {
        return contentRelay
            .asDriver(onErrorJustReturn: [])
    }
    
    private let bag = DisposeBag()
    
    init() {
        searchSubject
            .asObservable()
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(0.5, scheduler: MainScheduler.instance)
            .flatMapLatest { [unowned self] term -> Observable<[T]> in
                // every new try to search, the error signal will
                // emit nil to hide the error view
                self.errorSubject.onNext(nil)
                // switch to loading mode
                self.loadingSubject.onNext(true)
                
                self.lastQuery = term

                return self.search(byTerm: term)
                    .catchError { [unowned self] error -> Observable<[T]> in
                        self.errorSubject.onNext(SearchError.underlyingError(error))
                        return Observable.empty()
                }
            }
            .subscribe(onNext: { [unowned self] elements in
                self.loadingSubject.onNext(false)

                if elements.isEmpty {
                    self.errorSubject.onNext(SearchError.notFound)
                } else {
                    self.contentRelay.accept(elements)
                }
            })
            .disposed(by: bag)
    }
    
    func search(byTerm term: String) -> Observable<[T]> {
        fatalError("Override this function with your custom implementation")
    }
}
