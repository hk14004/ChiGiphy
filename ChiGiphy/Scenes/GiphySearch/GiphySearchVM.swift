//
//  GiphySearchVM.swift
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

class GiphySearchVM: GiphySearchVMProtocol {
    
    // MARK: Contants
    
    let pageSize = 20
    
    let loadWhenItemsLeft = 0
    
    let queryDebounce = 0.5
    
    // MARK: Input
        
    @VMInput var indexPathWillBeShownInput: AnyObserver<IndexPath>
    
    @VMInput var queryInput: AnyObserver<String>
    
    // MARK: Output
    
    @VMOutput(.initial(InitialGiphyCellVM())) var stateOutput: Observable<GiphySearchState>
    
    // MARK: Private
    
    private let giphyService: GiphyServiceProtocol
    
    private var bag = DisposeBag()
    
    private(set) var fetchedItemVMs = BehaviorRelay<[GiphyCellVM]>(value: [])
    
    private(set) var loadMoreDisposables = DisposeBag()
    
    private(set) var searchDisposables = DisposeBag()
    
    // MARK: Init

    init(giphyService: GiphyServiceProtocol = GiphyService()) {
        self.giphyService = giphyService
        
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        Observable.merge(
            respondToSearchInput(),
            respondToLoadMoreScrollInput()
        )
        .bind(to: $stateOutput).disposed(by: bag)
    }
    
    private func respondToSearchInput() -> Observable<GiphySearchState> {
        $queryInput
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(queryDebounce, scheduler: DriverSharingStrategy.scheduler)
            .flatMapLatest { [unowned self] term -> Observable<GiphySearchState> in
                performSearchRequest(with: term)
            }
    }
    
    private func respondToLoadMoreScrollInput() -> Observable<GiphySearchState> {
        $indexPathWillBeShownInput
            .map { [unowned self] in
                shouldLoadNextPage(indexPath: $0)
            }
            .distinctUntilChanged()
            .filter { $0 }
            .withLatestFrom($queryInput) { $1 } // Returns query
            .flatMapLatest { [unowned self]  query in
                performLoadMoreRequest(with: query)
            }
    }
    
    private func performSearchRequest(with term: String) -> Observable<GiphySearchState> {
        Observable<GiphySearchState>.create { [unowned self] (observer) -> Disposable in
            // Dispose of pending requests
            loadMoreDisposables = DisposeBag()
            searchDisposables = DisposeBag()

            // Perform query
            observer.onNext(.searching(SearchingGiphyCellVM()))
            giphyService.search(text: term, offset: 0, limit: pageSize)
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
    
    private func performLoadMoreRequest(with term: String) -> Observable<GiphySearchState> {
        Observable<GiphySearchState>.create { [unowned self] (observer) -> Disposable in
            // Dispose of pending requests
            loadMoreDisposables = DisposeBag()

            // Perform load more
            observer.onNext(.loadingMore(fetchedItemVMs.value, LoadingMoreCellVM()))
            giphyService.search(text: term, offset: fetchedItemVMs.value.count + 1, limit: pageSize)
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
    
    func getCurrentState() -> GiphySearchState {
        $stateOutput.value
    }
}
