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
        // Given
        let sut = makeSUT()
        let observer = testScheduler.createObserver(GiphySearchState.self)
        sut.state.bind(to: observer).disposed(by: bag)
        
        // Then
        testScheduler.start()
        XCTAssertEqual(observer.events, [
            .next(0, .initial(InitialGiphyCellVM())),
        ])
    }
    
    func test_foundState_afterInitialState_withMultipleItems() {
        // Given
        let successResult: [GiphyItem] = [
            .init(id: "id1", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!)),
            .init(id: "id2", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!))
        ]
        
        stubbedService.stubbedResults.append(Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success(successResult))
            return Disposables.create()
        })
        
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(sut.getSearchDebounce(), .searching(SearchingGiphyCellVM())),
                .next(sut.getSearchDebounce(), .found(successResult.map { GiphyCellVM(item: $0) }))
            ])
        }
    }
    
    func test_notFoundState_afterInitialState() {
        // Given
        stubbedService.stubbedResults.append(Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success([]))
            return Disposables.create()
        })
        
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            sut.query.accept("A query")
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(sut.getSearchDebounce(), .searching(SearchingGiphyCellVM())),
                .next(sut.getSearchDebounce(), .notFound(NotFoundGiphyCellVM()))
            ])
        }
    }
    
    func test_fetchNextPage_returnsNothing_afterInitialState() {
        // Given
        let indexPathWillBeShown = IndexPath(row: 0, section: 0)
        
        let sut = makeSUT()
        
        /// Listens for search state
        let stateObserver = testScheduler.createObserver(GiphySearchState.self)
        sut.state.bind(to: stateObserver).disposed(by: bag)
        
        // When
        /// Spoofed will display indexpath after initial state
        let userScrool = testScheduler.createHotObservable([next(100, indexPathWillBeShown)])
        
        /// Listens for indexpath change
        let indexPathObserver = testScheduler.createObserver(IndexPath.self)
        
        /// Register bindings
        userScrool.bind(to: sut.indexPathWillBeShown).disposed(by: bag)
        sut.indexPathWillBeShown.bind(to: indexPathObserver).disposed(by: bag)
        
        // Then
        /// Look for state still in initial and indexpath of will display did change
        testScheduler.start()
        /// Check  state still is initial
        XCTAssertEqual(stateObserver.events, [
            .next(0, .initial(InitialGiphyCellVM())),
        ])
        
        /// Check if there was input in indexpathWillBeShown
        XCTAssertEqual(indexPathObserver.events, [
            .next(100, indexPathWillBeShown),
        ])
    }
    
    func test_foundState_returnsSingle_afterFoundState() {
        // Given
        let firstResult: [GiphyItem] = [
            .init(id: "id1", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!)),
            .init(id: "id2", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!))
        ]
        
        let secondResult: [GiphyItem] = [
            .init(id: "id3", image: GiphyItem.Image(height: "", width: "", url: URL(string: "www.google.lv")!))
        ]
        
        stubbedService.stubbedResults.append(Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success(firstResult))
            return Disposables.create()
        })
        
        stubbedService.stubbedResults.append(Single<[GiphyItem]>.create { (observable) -> Disposable in
            observable(.success(secondResult))
            return Disposables.create()
        })
        
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = testScheduler.createObserver(GiphySearchState.self)
            sut.state.bind(to: observer).disposed(by: bag)
            
            // When
            /// Needs to fire querie in specific times
            let searchDebounce = sut.getSearchDebounce()
            let spoofUserInput = testScheduler.createHotObservable([
                next(0, "Success query 1"),
                next(searchDebounce + 1, "Success query 2")
            ])
            spoofUserInput.bind(to: sut.query).disposed(by: bag)
            
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(firstResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce * 2 + 1, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce * 2 + 1, .found(secondResult.map { GiphyCellVM(item: $0) }))
            ])
        }
    }
    
    private func makeSUT() -> TDDGiphySearchVM {
        return TDDGiphySearchVM(giphyService: stubbedService)
    }
}

// MARK: Helpers

extension TDDGiphySearchVM {
    convenience init(stubbedGiphyService: GiphyServiceProtocol = StubbedGiphyService()) {
        self.init(giphyService: stubbedGiphyService)
    }
    
    func getSearchDebounce() -> Int {
        return Int(queryDebounce * 1000)
    }
}

class StubbedGiphyService: GiphyServiceProtocol {
    var stubbedResults: [Single<[GiphyItem]>] = []
    
    func search(text: String = "", offset: Int = 0, limit: Int = 0) -> Single<[GiphyItem]> {
        return stubbedResults.removeFirst()
    }
}
