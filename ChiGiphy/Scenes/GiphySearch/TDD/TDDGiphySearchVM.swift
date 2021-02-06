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
        state.skip(1).delay(0.1, scheduler: MainScheduler.instance).bind(to: relay).disposed(by: bag)
        return relay
    }()
    
    var state: Observable<GiphySearchState> {
        Observable.merge(
            .just(.initial(InitialGiphyCellVM())),
            search(with: query),
            loadMore()
        ).share()
    }
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    private var bag = DisposeBag()
    
    private(set) var fetchedItemVMs = BehaviorRelay<[GiphyCellVM]>(value: [])
    
    private(set) var loadMoreDisposables = DisposeBag()
    
    // MARK: Init

    init(giphyService: GiphyServiceProtocol = GiphyService()) {
        self.giphyService = giphyService
    }
    
    // MARK: Methods
    
    private func search(with query: BehaviorRelay<String>) -> Observable<GiphySearchState> {
        query
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(queryDebounce, scheduler: DriverSharingStrategy.scheduler)
            .flatMapLatest { [unowned self] term -> Observable<[GiphyItem]> in
                // Dispose of load more request
                loadMoreDisposables = DisposeBag()
                // Perform query
                return giphyService.search(text: term, offset: 0, limit: self.pageSize).asObservable().retry()
            }.map { [unowned self] (items) -> GiphySearchState in
                if items.isEmpty {
                    return .notFound(NotFoundGiphyCellVM())
                }
                let fetched = items.map { GiphyCellVM(item: $0) }
                fetchedItemVMs.accept(fetched)
                return .found(fetched)
            }
    }
    
    private func loadMore() -> Observable<GiphySearchState> {
        indexPathWillBeShown
            .filter { self.shouldLoadItems(indexPath: $0) }
            .distinctUntilChanged()
            .flatMapLatest {[unowned self] _ -> Observable<[GiphyItem]>  in
                return giphyService.search(text: query.value, offset: fetchedItemVMs.value.count + 1, limit: self.pageSize).asObservable().retry()
            }.map { [unowned self] (items) -> GiphySearchState in
                let newList = fetchedItemVMs.value + items.map { GiphyCellVM(item: $0) }
                fetchedItemVMs.accept(newList)
                return .found(newList)
            }
    }
    
    func shouldLoadItems(indexPath: IndexPath) -> Bool {
        if fetchedItemVMs.value.isEmpty {
            return false
        }
        return fetchedItemVMs.value.count - (indexPath.row + 1)  <= loadWhenItemsLeft
    }
}
