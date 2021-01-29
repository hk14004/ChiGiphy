//
//  TDDGiphySearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

enum GiphySearchState: Equatable {
    case found([GiphyCellVM])
    case notFound(NotFoundGiphyCellVM)
    case initial(InitialGiphyCellVM)
    case searching(SearchingGiphyCellVM)
}

class TDDGiphySearchVM {
    
    var state: Observable<GiphySearchState> {
        Observable.merge(
            .just(.initial(InitialGiphyCellVM())),
            search(with: query)
        )
    }
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    init(giphyService: GiphyServiceProtocol) {
        self.giphyService = giphyService
    }
    
    var bag = DisposeBag()
    
    private func search(with query: BehaviorRelay<String>) -> Observable<GiphySearchState> {
        query
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(0.5, scheduler: DriverSharingStrategy.scheduler)
            .flatMapLatest { [unowned self] term -> Observable<GiphySearchState> in
                let fetch = giphyService.search(text: term, offset: 0, limit: 0).asObservable().materialize()
                // RxSwift 6 compact map would be nicer
                let elements = fetch
                    .map { $0.element }
                    .filter { $0 != nil }
                    .map { $0! }
                
                let errors = fetch
                    .map { $0.error }
                    .filter { $0 != nil }
                    .map { $0! }
                
                return Observable<GiphySearchState>.create { (observer) -> Disposable in
                    observer.onNext(.searching(SearchingGiphyCellVM()))
                    elements.subscribe(onNext: { fetched in
                        if fetched.isEmpty {
                            observer.onNext(.notFound(NotFoundGiphyCellVM()))
                        } else {
                            observer.onNext(.found(fetched.map { GiphyCellVM(item: $0)}))
                        }
                    }).disposed(by: bag)
                    
                    // TODO: Add error case
                    errors.subscribe(onNext: { error in
                        
                    }).disposed(by: bag)
                    
                    return Disposables.create()
                }
            }
    }
}
