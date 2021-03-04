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
    
    let loadWhenItemsLeft = 10
    
    let queryDebounce = 0.5
    
    // MARK: Input
        
    @VMInput var indexPathWillBeShownInput: AnyObserver<IndexPath>
    
    @VMInput var queryInput: AnyObserver<String>
    
    // MARK: Output
    
    @VMProperty(.initial(.init())) var stateOutput: Observable<GiphySearchState>
    
    @VMOutput var errorOutput: Observable<Error>
    
    // MARK: Private
        
    private let feedManger: QueryableFeedManager<GiphyItem>
    
    private var bag = DisposeBag()
    
    // MARK: Init

    init() {
        self.feedManger = QueryableFeedManager<GiphyItem>(feedProvider: AnyQueryableFeed<GiphyItem>(GiphyQueryableFeed()),
                                                          onPageError: .retry(.delayed(maxCount: UInt.max, time: 3)))
        setup()
    }
    
    // MARK: Methods
    
    // TODO: State machine would probably be better
    private func setup() {
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
        
        feedManger.errorOutput.bind(to: $errorOutput).disposed(by: bag)

    }
    
    func getCurrentState() -> GiphySearchState {
        $stateOutput.value
    }
}
