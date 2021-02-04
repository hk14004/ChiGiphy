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
    
    var indexPathWillBeShown = PublishRelay<IndexPath>()
    
    lazy var stateRelay: BehaviorRelay<GiphySearchState> = {
        let relay = BehaviorRelay<GiphySearchState>(value: .initial(InitialGiphyCellVM()))
        state.bind(to: relay).disposed(by: bag)
        return relay
    }()
    
    lazy var stateDriver: Driver<GiphySearchState> = {
        stateRelay.asDriver()
    }()
        
        
    var state: Observable<GiphySearchState> {
        Observable.merge(
            .just(.initial(InitialGiphyCellVM())),
            search(with: query),
            loadMore()
        ).share().delay(0.1, scheduler: MainScheduler.instance)
    }
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    var bag = DisposeBag()
    
    private var fetchedItemVMs = BehaviorRelay<[GiphyCellVM]>(value: [])
    
    func shouldLoadItems(indexPath: IndexPath) -> Bool {
        if fetchedItemVMs.value.isEmpty {
            return false
        }
        return fetchedItemVMs.value.count - (indexPath.row + 1)  <= loadWhenItemsLeft
    }
    
    private(set) var loadMoreDisposables = DisposeBag()
    
    // MARK: Init

    init(giphyService: GiphyServiceProtocol = GiphyService()) {
        self.giphyService = giphyService
    }
    
    // MARK: Methods
    private func loadMore() -> Observable<GiphySearchState> {
        indexPathWillBeShown
            .filter {
                self.shouldLoadItems(indexPath: $0)
            }
            .distinctUntilChanged()
            .flatMapLatest {[unowned self] _ -> Observable<GiphySearchState>  in
                let fetchRequest = giphyService.search(text: query.value, offset: fetchedItemVMs.value.count + 1, limit: self.pageSize).asObservable().catchErrorJustReturn([]).share()
                let materializedFetchRequest = MaterializedObservable(observable: fetchRequest)
                
                return Observable<GiphySearchState>.create { (observer) -> Disposable in
                    observer.onNext(.loadingMore(fetchedItemVMs.value,LoadingMoreCellVM()))
                    materializedFetchRequest.elements.subscribe(onNext: { fetched in
                        let results = fetched.map { GiphyCellVM(item: $0)}
                        fetchedItemVMs.accept(fetchedItemVMs.value + results)
                        observer.onNext(.found(fetchedItemVMs.value))
                    }).disposed(by: loadMoreDisposables)
                    
                    // TODO: Add error case
                    materializedFetchRequest.errors.subscribe(onNext: { error in
                        print("Next page error:", error.localizedDescription)
                    })
                    .disposed(by: loadMoreDisposables)
                    
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
                // Dispose of loadMore
                loadMoreDisposables = DisposeBag()
                // Perform query
                let fetchRequest = giphyService.search(text: term, offset: 0, limit: self.pageSize).asObservable().retry().share()
                let materializedFetchRequest = MaterializedObservable(observable: fetchRequest)
                
                return Observable<GiphySearchState>.create { (observer) -> Disposable in
                    observer.onNext(.searching(SearchingGiphyCellVM()))
                    materializedFetchRequest.elements.subscribe(onNext: { fetched in
                        if fetched.isEmpty {
                            observer.onNext(.notFound(NotFoundGiphyCellVM()))
                        } else {
                            let items = fetched.map { GiphyCellVM(item: $0)}
                            fetchedItemVMs.accept(items)
                            observer.onNext(.found(items))
                        }
                    }).disposed(by: bag)
                    
                    // TODO: Add error case
                    materializedFetchRequest.errors.subscribe(onNext: { error in
                        print("Search error:", error.localizedDescription)
                    }).disposed(by: bag)
                    
                    return Disposables.create()
                }
            }
    }
}

class MaterializedObservable<T> {
    
    let elements: Observable<T>
    
    let errors: Observable<Error>
    
    init(observable: Observable<T>) {
        let materialized = observable.materialize()
        
        self.elements = materialized
            .map { $0.element }
            .filter { $0 != nil }
            .map { $0! }
        
        self.errors = materialized
            .map { $0.error }
            .filter { $0 != nil }
            .map { $0! }
    }
}
