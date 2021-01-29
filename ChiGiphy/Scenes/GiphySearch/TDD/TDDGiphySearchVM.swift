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
    case loadingMore(LoadingMoreVM)
}

class TDDGiphySearchVM {
    
    /// Gif page size
    static private let pageSize = 20
    
    /// Load new page when x elemnts left to display
    static private let loadWhenItemsLeft = 10
    
    /// Query input interval
    let queryDebounce = 0.5
    
    var indexPathWillBeShown = PublishRelay<IndexPath>()
    
    var state: Observable<GiphySearchState> {
        Observable.merge(
            .just(.initial(InitialGiphyCellVM())),
            search(with: query),
            loadMore()
        )
    }
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    init(giphyService: GiphyServiceProtocol) {
        self.giphyService = giphyService
    }
    
    var bag = DisposeBag()
    
    private var fetchedItems = BehaviorRelay<[GiphyItem]>(value: [])
    
    private var fetchedItemVMs = BehaviorRelay<[GiphyCellVM]>(value: [])
    
    private func loadMore() -> Observable<GiphySearchState> {
        // TODO: Check state is found before requesting next page
        indexPathWillBeShown
            .filter {
            if self.fetchedItems.value.isEmpty {
                return false
            }
            return self.fetchedItems.value.count - $0.row <= 10
        }.distinctUntilChanged()
        .flatMapLatest {[unowned self] _ -> Observable<GiphySearchState>  in
            let fetch = giphyService.search(text: query.value, offset: fetchedItemVMs.value.count + 1, limit: Self.pageSize).asObservable().materialize()
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
                observer.onNext(.loadingMore(LoadingMoreVM()))
                elements.subscribe(onNext: { fetched in
                    if fetched.isEmpty {
                        // TODO: Stuck in loading
                        //observer.onNext(.found())
                    } else {
                        let results = fetched.map { GiphyCellVM(item: $0)}
                        observer.onNext(.found(fetchedItemVMs.value + results))
                    }
                }).disposed(by: bag)
                
                // TODO: Add error case
                errors.subscribe(onNext: { error in
                    
                }).disposed(by: bag)
                
                return Disposables.create()
            }
        }
    }
    
    private func search(with query: BehaviorRelay<String>) -> Observable<GiphySearchState> {
        query
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(queryDebounce, scheduler: DriverSharingStrategy.scheduler)
            .flatMapLatest { [unowned self] term -> Observable<GiphySearchState> in
                let fetch = giphyService.search(text: term, offset: fetchedItemVMs.value.count + 1, limit: Self.pageSize).asObservable().materialize()
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
                            let items = fetched.map { GiphyCellVM(item: $0)}
                            fetchedItemVMs.accept(items)
                            observer.onNext(.found(items))
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
