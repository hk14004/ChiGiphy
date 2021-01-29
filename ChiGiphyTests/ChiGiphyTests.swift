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
        let sut = TDDGiphySearchVM()
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
        
        let sut = TDDGiphySearchVM(giphyService: stubbedService)
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(500, .searching(SearchingGiphyCellVM())),
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
        
        let sut = TDDGiphySearchVM(giphyService: stubbedService)
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(500, .searching(SearchingGiphyCellVM())),
                .next(500, .notFound(NotFoundGiphyCellVM()))
            ])
        }
        
    }
}

// MARK: Helpers

class GiphySearchStateSpy {
    
    private(set) var state: [GiphySearchState] = []
    
    private let bag = DisposeBag()
    
    init(observableState: Observable<GiphySearchState>) {
        observableState.subscribe(onNext: { [weak self] state in
            self?.state.append(state)
        }).disposed(by: bag)
    }
}

extension TDDGiphySearchVM {
    convenience init(stubbedGiphyService: GiphyServiceProtocol = StubbedGiphyService()) {
        self.init(giphyService: stubbedGiphyService)
    }
}

class StubbedGiphyService: GiphyServiceProtocol {
        
    var stubbedResult: Single<[GiphyItem]>!
    
    func search(text: String = "", offset: Int = 0, limit: Int = 0) -> Single<[GiphyItem]> {
        return stubbedResult
    }
}
