//
//  GiphySearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit
import RxSwift
import RxCocoa

class GiphySearchVM {
    
    //MARK: Constants
    
    /// Gif page size
    static private let pageSize = 20
    
    /// Load new page when x elemnts left to display
    static private let loadWhenItemsLeft = 10
    
    /// Search input update frequency
    static private let searchFrequence = 0.5
    
    //MARK: Input
    
    /// Binded to searchBar
    private(set) var searchQuery = BehaviorRelay(value: "") /// Should we expose relays like that?
    
    /// Bindded to will display cell
    private(set) var contentWillBeShownAt = BehaviorRelay(value: IndexPath(row: 0, section: 0)) /// Should we expose relays like that?
    
    //MARK: Output
    
    /// Collection view display data driver
    var sectionData: Driver<[GiphySection]> {
        return _fetchedItems.asDriver().map { items -> [GiphySection] in
            return [GiphySection(model: .init(), items: items)]
        }
    }
    
    // MARK: Internal vars
    
    /// Gif item cache
    private var _fetchedItems = BehaviorRelay<[GiphyItem]>(value: [])
        
    private let _disposeBag = DisposeBag()
    
    //MARK: Init
    
    
    init() {
        // TODO: Pass in service protocol
    }
    
    //MARK: Methods
    
    private func shouldLoadNextPage(willDisplaytemAt: IndexPath) -> Bool {
        return willDisplaytemAt.row == _fetchedItems.value.count - Self.loadWhenItemsLeft
    }
    
    func load() {
        
        //TODO: Check self leak when in closures
        //TODO: Make sure next page requests are serial
        //TODO: Network result as Single?
        //TODO: Is next page query inline with search query when requesting new items?
        //TODO: Handle on error
        
        /// Listens for search inputs and fetches data
        searchQuery.throttle(Self.searchFrequence, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { query -> Observable<[GiphyItem]> in
                return GiphyService.shared.search(text: query, limit: Self.pageSize).catchErrorJustReturn([])
            }.subscribe { [weak self] (searchedBatch) in
                self?._fetchedItems.accept(searchedBatch)
            }.disposed(by: _disposeBag)


        /// Listen for scroll state and requests next page
        contentWillBeShownAt.map { indexpath in
            return self.shouldLoadNextPage(willDisplaytemAt: indexpath)
        }.distinctUntilChanged()
        .filter { loadNextPage -> Bool in
            return loadNextPage
        }
        .flatMapLatest { _ -> Observable<[GiphyItem]> in
            print("load next page, fire request")
            return GiphyService.shared.search(text: self.searchQuery.value, offset: self._fetchedItems.value.count + 1, limit: Self.pageSize).catchErrorJustReturn([])
        }.subscribe(onNext: { [weak self] nextPageBatch in
            guard let self = self else { return }
            self._fetchedItems.accept(self._fetchedItems.value + nextPageBatch)
        }).disposed(by: _disposeBag)
    }
}
