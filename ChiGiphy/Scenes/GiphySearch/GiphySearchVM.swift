//
//  GiphySearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit
import RxSwift
import RxCocoa

class GiphySearchVM: GenericSearchVM<GiphyItem>, GiphySearchVMProtocol {
    
    // MARK: Constants
    
    let title = NSLocalizedString("Giphy Searcher", comment: "")
    
    let gifColumns = 2
    
    /// Gif page size
    static private let pageSize = 20
    
    /// Load new page when x elemnts left to display
    static private let loadWhenItemsLeft = 10
    
    // MARK: Input
    
    /// Binded to will display cell
    private let indexPathWillBeShownSubject = PublishSubject<IndexPath>()
    
    var indexPathWillBeShown: AnyObserver<IndexPath> {
        indexPathWillBeShownSubject.asObserver()
    }
    
    // MARK: Output
    
    /// Collection view display data driver
    var sectionData: Driver<[GiphySection]> {
        return contentRelay.asDriver().map { items -> [GiphySection] in
            return [GiphySection(model: .init(), items: items)]
        }
    }
    
    // MARK: Internal vars
    
    private let disposeBag = DisposeBag()
    
    // MARK: Init
    
    override init() {
        super.init()
        getNextPageBasedOnVisibleCell()
    }
    
    // MARK: Methods
    
    private func getNextPageBasedOnVisibleCell() {
        // Listen for scroll state and requests next page
        indexPathWillBeShownSubject.map { indexpath in
            return self.shouldLoadNextPage(willDisplayItemAt: indexpath)
        }.distinctUntilChanged()
        .bind(to: fetchNextPageRelay)
        .disposed(by: disposeBag)
    }
    
    private func shouldLoadNextPage(willDisplayItemAt: IndexPath) -> Bool {
        return willDisplayItemAt.row >= contentRelay.value.count - Self.loadWhenItemsLeft
    }
    
    override func search(byTerm term: String) -> Observable<[GiphyItem]> {
        GiphyService.shared.search(text: term, limit: Self.pageSize)
    }
        
    override func getNextPage() -> Observable<[GiphyItem]> {
        return GiphyService.shared.search(text: searchQueryRelay.value,
                                          offset: contentRelay.value.count + 1,
                                          limit: Self.pageSize)
    }
    
    func getGifSize(at indexPath: IndexPath) -> CGSize {
        let image = contentRelay.value[indexPath.row].image
        return CGSize(width: Int(image.width) ?? 0, height: Int(image.height) ?? 0)
    }
}
