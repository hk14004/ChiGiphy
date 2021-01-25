//
//  GiphySearchVM.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit
import RxSwift
import RxCocoa

class GiphySearchVM: GenericSearchVM<GiphyItem> {
    
    //MARK: Constants
    
    let title = NSLocalizedString("Giphy Searcher", comment: "")
    
    let gifColumns = 2
    
    /// Gif page size
    static private let pageSize = 20
    
    /// Load new page when x elemnts left to display
    static private let loadWhenItemsLeft = 10
    
    //MARK: Input
    
    /// Binded to will display cell
    private let indexPathWillBeShownSubject = PublishSubject<IndexPath>() // Better to have BRelay?
    
    var indexPathWillBeShown: AnyObserver<IndexPath> {
        indexPathWillBeShownSubject.asObserver()
    }
    
    //MARK: Output
    
    /// Collection view display data driver
    var sectionData: Driver<[GiphySection]> {
        return content.map { items -> [GiphySection] in
            return [GiphySection(model: .init(), items: items)]
        }
    }
    
    // MARK: Internal vars
    
    private let disposeBag = DisposeBag()
    
    //MARK: Init
    
    override init() {
        super.init()
        // Listen for scroll state and requests next page
        indexPathWillBeShownSubject.map { indexpath in
            return self.shouldLoadNextPage(willDisplaytemAt: indexpath)
        }.distinctUntilChanged()
        .filter { loadNextPage -> Bool in
            return loadNextPage
        }
        .flatMapLatest { _ -> Observable<[GiphyItem]> in
            self.loadingSubject.onNext(true)
            return self.getNextPage()
                .catchError { [unowned self] error -> Observable<[GiphyItem]> in
                    self.errorSubject.onNext(SearchError.underlyingError(error))
                    return Observable.empty()
                }
        }.subscribe(onNext: { [unowned self] nextPageBatch in
            loadingSubject.onNext(false)
            contentRelay.accept(contentRelay.value + nextPageBatch)
        }).disposed(by: disposeBag)
    }
    
    //MARK: Methods
    
    private func shouldLoadNextPage(willDisplaytemAt: IndexPath) -> Bool {
        return willDisplaytemAt.row == contentRelay.value.count - Self.loadWhenItemsLeft
    }
    
    override func search(byTerm term: String) -> Observable<[GiphyItem]> {
        GiphyService.shared.search(text: term, limit: Self.pageSize)
    }
    
    // TODO: Move loading state to this function
    private func getNextPage() -> Observable<[GiphyItem]> {
        return GiphyService.shared.search(text: lastQuery,
                                          offset: contentRelay.value.count + 1,
                                          limit: Self.pageSize)
    }
    
    func getGifSize(at indexPath: IndexPath) -> CGSize {
        let image = contentRelay.value[indexPath.row].image
        return CGSize(width: Int(image.width) ?? 0, height: Int(image.height) ?? 0)
    }
}
