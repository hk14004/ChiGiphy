//
//  GenericQueryableFeed.swift
//  ChiGiphy
//
//  Created by Hardijs on 04/03/2021.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

protocol GenericQueryableFeed {
    associatedtype Item

    var pageSize: Int { get }
    var feedSize: Int { get }
    
    func search(query: String) -> Observable<[Item]>
    func getNextPage() -> Observable<[Item]>
}

protocol QueryableFeedManagerInput {
    var queryInput: PublishSubject<String> { get }
    var getNextPageTriggerInput: PublishSubject<Void> { get }
}

protocol QueryableFeedManagerOutput {
    associatedtype Item
    var performingQueryOutput: Observable<Bool> { get }
    var performingGetNextPageOutput: Observable<Bool> { get }
    var itemsOutput: Observable<[Item]> { get }
    var errorOutput: Observable<Error> { get }
}

typealias QueryableFeedManagerType = QueryableFeedManagerInput & QueryableFeedManagerOutput

struct QueryableFeedManager<Item: Equatable>: QueryableFeedManagerType {
    
    // MARK: Input
    
    let queryInput = PublishSubject<String>()
    
    let getNextPageTriggerInput = PublishSubject<Void>()
    
    // MARK: Output
    
    let performingQueryOutput: Observable<Bool>
    
    let performingGetNextPageOutput: Observable<Bool>
    
    let itemsOutput: Observable<[Item]>
    
    var errorOutput: Observable<Error>
    
    // MARK: Services
    
    private let feedProvider: AnyQueryableFeed<Item>
    
    // MARK: Types
    
    enum OnPageError {
        case retry(RepeatBehavior)
        case giveUp
        case silentlyReturn([Item])
    }
    
    // MARK: Init
    
    init(feedProvider: AnyQueryableFeed<Item>,
         onPageError: OnPageError = .silentlyReturn([]))
    {
        // Services
        self.feedProvider = feedProvider
        
        let errors = PublishSubject<Error>()
        
        // Property bindings
        let accumulatedItems = BehaviorRelay<[Item]>(value: [])
        
        let searchResults = queryInput.flatMapLatest { (query) -> Observable<[Item]> in
            let request = feedProvider.search(query: query)
            switch onPageError {
            case .retry(let retryBehaviour):
                return request.retry(retryBehaviour).catchError { (error) -> Observable<[Item]> in
                    errors.onNext(error)
                    return .just([])
                }
            case .giveUp:
                return request.catchError { (error) -> Observable<[Item]> in
                    errors.onNext(error)
                    return .just([])
                }
            case .silentlyReturn(let items):
                return request.catchErrorJustReturn(items)
            }
        }.do(onNext: { results in
            accumulatedItems.accept(results)
        }).share()
        
        let loadMoreResults = getNextPageTriggerInput.asObservable().flatMapLatest { _ -> Observable<[Item]> in
            let request = feedProvider.getNextPage()
            switch onPageError {
            case .retry(let retryBehaviour):
                return request.retry(retryBehaviour).catchError { (error) -> Observable<[Item]> in
                    errors.onNext(error)
                    return .just([])
                }
            case .giveUp:
                return request.catchError { (error) -> Observable<[Item]> in
                    errors.onNext(error)
                    return .just([])
                }
            case .silentlyReturn(let items):
                return request.catchErrorJustReturn(items)
            }
        }.do(onNext: { loaded in
            accumulatedItems.accept(accumulatedItems.value + loaded)
        }).share()
        
        performingQueryOutput = Observable<Bool>.merge(
            queryInput.map { _ in true },
            searchResults.map { _ in false }
        )
        
        performingGetNextPageOutput = Observable<Bool>.merge(
            getNextPageTriggerInput.map { _ in true },
            loadMoreResults.map { _ in false }
        )
        
        itemsOutput = accumulatedItems.asObservable()
        errorOutput = errors.asObservable()
    }
}

class AnyQueryableFeed<Item>: GenericQueryableFeed {
    
    // TODO: Type erese properties
    
    var pageSize: Int = 0
    
    var feedSize: Int = 0
        
    private let _search: ((String) -> Observable<[Item]>)
    
    private let _getNextPage: () -> Observable<[Item]>

    init<Base: GenericQueryableFeed>(_ base: Base) where Item == Base.Item {
        _search = base.search
        _getNextPage = base.getNextPage
    }
    
    func search(query: String) -> Observable<[Item]> {
        _search(query)
    }
    
    func getNextPage() -> Observable<[Item]> {
        _getNextPage()
    }
}
