//
//  TDDGiphySearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

enum GiphySearchState: Equatable {
    case found([GiphyCellVM])
    case notFound(NotFoundGiphyCellVM)
    case initial(InitialGiphyCellVM)
    case searching(SearchingGiphyCellVM)
    case loadingMore([GiphyCellVM], LoadingMoreCellVM)
}

class TDDGiphySearchVM {
    
    /// Gif page size
    let pageSize = 20
    
    /// Load new page when x elemnts left to display
    let loadWhenItemsLeft = 0
    
    /// Query input interval
    let queryDebounce = 0.5

    private(set) var indexPathWillBeShown = PublishRelay<IndexPath>()
    
    private(set) lazy var stateRelay: BehaviorRelay<GiphySearchState> = {
        let relay = BehaviorRelay<GiphySearchState>(value: .initial(InitialGiphyCellVM()))
        Observable.merge(
            respondToSearchInput(),
            respondToLoadMoreScrollInput()
        )
        .bind(to: relay).disposed(by: bag)
        return relay
    }()
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    private var bag = DisposeBag()
    
    private(set) var fetchedItemVMs = BehaviorRelay<[GiphyCellVM]>(value: [])
    
    private(set) var loadMoreDisposables = DisposeBag()
    
    private(set) var searchDisposables = DisposeBag()
    
    // MARK: Init

    init(giphyService: GiphyServiceProtocol = GiphyService()) {
        self.giphyService = giphyService
    }
    
    // MARK: Methods
    
    private func respondToSearchInput() -> Observable<GiphySearchState> {
        query
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(queryDebounce, scheduler: DriverSharingStrategy.scheduler)
            .flatMapLatest { [unowned self] term -> Observable<GiphySearchState> in
               performSearchRequest(with: term)
            }
    }
    
    private func respondToLoadMoreScrollInput() -> Observable<GiphySearchState> {
        indexPathWillBeShown
            .filter { self.shouldLoadNextPage(indexPath: $0) }
            .distinctUntilChanged()
            .flatMapLatest { [unowned self]  _ in
                performLoadMoreRequest()
            }
    }
    
    private func performSearchRequest(with term: String) -> Observable<GiphySearchState> {
        Observable<GiphySearchState>.create { [unowned self] (observer) -> Disposable in
            // Dispose of pending requests
            loadMoreDisposables = DisposeBag()
            searchDisposables = DisposeBag()

            // Perform query
            observer.onNext(.searching(SearchingGiphyCellVM()))
            giphyService.search(text: term, offset: 0, limit: self.pageSize)
                .asObservable()
                .retry(.delayed(maxCount: UInt.max, time: 3))
                .subscribe { (items) in
                    guard !items.isEmpty else {
                        observer.onNext(.notFound(NotFoundGiphyCellVM()))
                        return
                    }
                    let fetched = items.map { GiphyCellVM(item: $0) }
                    fetchedItemVMs.accept(fetched)
                    observer.onNext(.found(fetched))
                } onError: { (error) in
                    print("Search errored out:", error.localizedDescription)
                } onDisposed: {
                  print("Search disposed")
                }.disposed(by: searchDisposables)

            return Disposables.create()
        }
    }
    
    private func performLoadMoreRequest() -> Observable<GiphySearchState> {
        Observable<GiphySearchState>.create { [unowned self] (observer) -> Disposable in
            // Dispose of pending requests
            loadMoreDisposables = DisposeBag()

            // Perform load more
            observer.onNext(.loadingMore(fetchedItemVMs.value, LoadingMoreCellVM()))
            giphyService.search(text: query.value, offset: fetchedItemVMs.value.count + 1, limit: self.pageSize)
                .asObservable()
                .retry(.delayed(maxCount: UInt.max, time: 3))
                .subscribe { (items) in
                    let fetched = items.map { GiphyCellVM(item: $0) }
                    fetchedItemVMs.accept(fetchedItemVMs.value + fetched)
                    observer.onNext(.found(fetchedItemVMs.value))
                } onError: { (error) in
                    print("Load more errored out:", error.localizedDescription)
                } onDisposed: {
                  print("Load more disposed")
                }.disposed(by: loadMoreDisposables)

            return Disposables.create()
        }
    }
    
    func shouldLoadNextPage(indexPath: IndexPath) -> Bool {
        if fetchedItemVMs.value.isEmpty {
            return false
        }
        return fetchedItemVMs.value.count - (indexPath.row + 1)  <= loadWhenItemsLeft
    }
}
