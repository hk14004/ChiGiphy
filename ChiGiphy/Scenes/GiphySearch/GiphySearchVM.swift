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
import RxReachability
import Reachability

class GiphySearchVM: GiphySearchVMProtocol {

    // MARK: Contants
    
    let loadWhenItemsLeft = 10
    
    let queryDebounce = 0.5
    
    // MARK: Input
        
    @VMInput var indexPathWillBeShownInput: AnyObserver<IndexPath>
    
    @VMInput var queryInput: AnyObserver<String>
    
    // MARK: Output
    
    @VMProperty(.initial(.init())) var stateOutput: Observable<GiphySearchState>
    
    @VMOutput var errorOutput: Observable<Error>
    
    @VMOutput var isRechableOutput: Observable<Bool>
    
    // MARK: Private
        
    private let feedManger: QueryableFeedManager<GiphyItem>
    
    private var bag = DisposeBag()
    
    private let reachabilityManager: ReachabilityManagerProtocol
    
    // MARK: Init

    init(reachabilityManager: ReachabilityManagerProtocol = ReachabilityManager.shared) {
        self.feedManger = QueryableFeedManager<GiphyItem>(feedProvider: AnyQueryableFeed<GiphyItem>(GiphyQueryableFeed()),
                                                          onPageError: .retry(.delayed(maxCount: UInt.max, time: 3)))
        self.reachabilityManager = reachabilityManager
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        bindFeedProvider()
        bindErrors()
        bindNetworkStatus()
    }
    
    private func bindFeedProvider() {
        // Respond to search -  input
        $queryInput
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(queryDebounce, scheduler: DriverSharingStrategy.scheduler)
            .bind(to: feedManger.queryInput)
            .disposed(by: bag)
        
        // Respond to search -  output
        feedManger.performingQueryOutput.filter{$0}.map { _ in .searching(.init()) }
            .bind(to: $stateOutput)
            .disposed(by: bag)
        
        let gifCellsOutput = feedManger.itemsOutput.skip(1).map { gifModels in gifModels.map { GiphyCellVM(item: $0) }}.share()
            
        gifCellsOutput.filter{$0.isEmpty}.map { _ in .notFound(.init())}
            .bind(to: $stateOutput)
            .disposed(by: bag)
        
        gifCellsOutput.filter{!$0.isEmpty}.map { .found($0) }
            .bind(to: $stateOutput)
            .disposed(by: bag)
        
        // Respond to load more -  input
        $indexPathWillBeShownInput
            .withLatestFrom(gifCellsOutput) { indexPath, cells in
                // Logic for calculating when to load more items
                guard !cells.isEmpty else { return false }
                return cells.count - (indexPath.row + 1)  <= self.loadWhenItemsLeft
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in }
            .bind(to: feedManger.getNextPageTriggerInput)
            .disposed(by: bag)
        
        // Respond to load more - output
        feedManger.performingGetNextPageOutput.filter{$0}.withLatestFrom(gifCellsOutput)
            .map { gifCells in  .loadingMore(gifCells, .init()) }
            .bind(to: $stateOutput)
            .disposed(by: bag)
    }
    
    private func bindErrors() {
        feedManger.errorOutput.bind(to: $errorOutput).disposed(by: bag)
    }
    
    private func bindNetworkStatus() {
        reachabilityManager.reachability.rx.isReachable.bind(to: $isRechableOutput).disposed(by: bag)

    }
    
    func getCurrentState() -> GiphySearchState {
        $stateOutput.value
    }
}

enum GiphySearchState: Equatable {
    case found([GiphyCellVM])
    case notFound(NotFoundGiphyCellVM)
    case initial(InitialGiphyCellVM)
    case searching(SearchingGiphyCellVM)
    case loadingMore([GiphyCellVM], LoadingMoreCellVM)
}

protocol GiphySearchVMProtocol {

    // MARK: Vars
    
    /// Load new page when x elements left to display
    var loadWhenItemsLeft: Int { get }
    
    /// Query input interval
    var queryDebounce: Double { get }
    
    // MARK: Input

    var indexPathWillBeShownInput: AnyObserver<IndexPath> { get }
    
    var queryInput: AnyObserver<String> { get }
    
    // MARK: Output
    
    var stateOutput: Observable<GiphySearchState> { get }
    
    var errorOutput: Observable<Error> { get }
    
    var isRechableOutput: Observable<Bool> { get }
    
    // MARK: Methods
    
    func getCurrentState() -> GiphySearchState
}

