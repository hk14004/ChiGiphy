//
//  ChiGiphyTests.swift
//  ChiGiphyTests
//
//  Created by Hardijs on 28/01/2021.
//

import XCTest
import RxTest
import RxBlocking
import RxSwift
import RxCocoa
@testable import ChiGiphy

protocol GiphyServiceProtocol {
    func search(text: String, offset: Int, limit: Int) -> Single<[GiphyItem]>
}

class StubbedGiphyService: GiphyServiceProtocol {
        
    var stubbedResult: Single<[GiphyItem]>!
    
    func search(text: String = "", offset: Int = 0, limit: Int = 0) -> Single<[GiphyItem]> {
        return stubbedResult
    }
}

class GiphyCellVM: Equatable {
    
    private let item: GiphyItem
    
    init(item: GiphyItem) {
        self.item = item
    }
    
    static func == (lhs: GiphyCellVM, rhs: GiphyCellVM) -> Bool {
        lhs.item == rhs.item
    }
}

class InitialGiphyCellVM: Equatable {
    static func == (lhs: InitialGiphyCellVM, rhs: InitialGiphyCellVM) -> Bool {
        true
    }
}

class NotFoundGiphyCellVM: Equatable {
    static func == (lhs: NotFoundGiphyCellVM, rhs: NotFoundGiphyCellVM) -> Bool {
        true
    }
}




class GiphySearchVM {
    
    var state: Observable<GiphySearchState> {
        Observable.merge(
            .just(.initial(InitialGiphyCellVM())),
            search(with: query)
        )
    }
    
    private(set) var query = BehaviorRelay<String>(value: "")
    
    private let giphyService: GiphyServiceProtocol
    
    init(giphyService: GiphyServiceProtocol = StubbedGiphyService()) {
        self.giphyService = giphyService
    }
    
    var bag = DisposeBag()
    
    private func search(with query: BehaviorRelay<String>) -> Observable<GiphySearchState> {
        query
            .filter { !$0.isEmpty }
            .distinctUntilChanged()
            .debounce(0.5, scheduler: SharingScheduler.make())
            .flatMapLatest { [unowned self] term -> Observable<GiphySearchState> in
                let fetch = giphyService.search(text: term, offset: 0, limit: 0).asObservable().materialize()
                let elements = fetch
                            .map { $0.element }
                            .filter { $0 != nil }
                            .map { $0! }
                
                let errors = fetch
                            .map { $0.error }
                            .filter { $0 != nil }
                            .map { $0! }
                
                return Observable<GiphySearchState>.create { (observer) -> Disposable in
                    elements.subscribe(onNext: { fetched in
                        if fetched.isEmpty {
                            observer.onNext(.notFound(NotFoundGiphyCellVM()))
                        } else {
                            observer.onNext(.found(fetched.map { GiphyCellVM(item: $0)}))
                        }
                    }).disposed(by: bag)
                
                    // TODO: Add error case
                    errors.subscribe(onNext: { error in
                        
                    }).disposed(by: bag)
                    
                    return Disposables.create()
                }
            }
        
    }
}


enum GiphySearchState: Equatable {
    case found([GiphyCellVM])
    case notFound(NotFoundGiphyCellVM)
    case initial(InitialGiphyCellVM)
}

class ChiGiphyTests: XCTestCase {

    // MARK: Variables
    
    private var bag = DisposeBag()
    
    private var testScheduler: TestScheduler!
    
    private var stubbedService: StubbedGiphyService!
    
    // MARK: XCTest
    
    override func setUp() {
        testScheduler = TestScheduler(initialClock: 0, resolution: 0.001)
        stubbedService = StubbedGiphyService()
    }
    override func tearDown() {
        bag = DisposeBag()
    }
    
    // MARK: Tests
    
    func test_initialState() {
        let sut = GiphySearchVM()
        let spy = GiphySearchStateSpy(observableState: sut.state)
        
        XCTAssertEqual(spy.state, [GiphySearchState.initial(InitialGiphyCellVM())])
    }
    
    func test_foundState_afterInitialState_withMultipleItems() {
        // Given
        let successResult: [GiphyItem] = [
            .init(id: "id1", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!)),
            .init(id: "id2", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!))
        ]
        
        stubbedService.stubbedResult = Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success(successResult))
            return Disposables.create()
        }
        
        let sut = GiphySearchVM(giphyService: stubbedService)
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(500, .found(successResult.map { GiphyCellVM(item: $0) }))
            ])
        }
    }
    
    func test_notFoundState_afterInitialState() {
        // Given
        stubbedService.stubbedResult = Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success([]))
            return Disposables.create()
        }
        
        let sut = GiphySearchVM(giphyService: stubbedService)
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(500, .notFound(NotFoundGiphyCellVM()))
            ])
        }
        
    }


    fileprivate class GiphySearchStateSpy {
        
        private(set) var state: [GiphySearchState] = []
        
        private let bag = DisposeBag()
        
        init(observableState: Observable<GiphySearchState>) {
            observableState.subscribe(onNext: { [weak self] state in
                self?.state.append(state)
            }).disposed(by: bag)
        }
    }
}
