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
        let observer = registerStateListener(for: sut)
        
        // Then
        testScheduler.start()
        XCTAssertEqual(observer.events, [
            .next(0, .initial(InitialGiphyCellVM())),
        ])
    }
    
    func test_foundState_afterInitialState_withMultipleItems() {
        // Given
        let successResult: [GiphyItem] = GiphyItem.createMocks(count: 2)
        stubbedService.addSingleStub { $0(.success(successResult)) }
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = registerStateListener(for: sut)
            
            // When
            let _ = spoofInput(for: sut.query, events: [next(0, "A query")])
            
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
        stubbedService.addSingleStub(onSubscribe: { $0(.success([])) })
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = registerStateListener(for: sut)
            
            // When
            let _ = spoofInput(for: sut.query, events: [next(0, "A query")])
            
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
        let stateObserver = registerStateListener(for: sut)
        
        // When
        /// Spoofed will display indexpath after initial state
        let _ = spoofInput(for: sut.indexPathWillBeShown, events: [next(100, indexPathWillBeShown)])
        
        /// Listens for indexpath change
        let indexPathObserver = testScheduler.createObserver(IndexPath.self)
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
        let firstResult: [GiphyItem] = GiphyItem.createMocks(count: 2)
        
        let secondResult: [GiphyItem] = GiphyItem.createMocks(count: 1)
        
        stubbedService.addSingleStub(onSubscribe: { $0(.success(firstResult)) })
        stubbedService.addSingleStub(onSubscribe: { $0(.success(secondResult)) })
        
        let sut = makeSUT()
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let stateObserver = registerStateListener(for: sut)
            
            // When
            /// Needs to fire query in specific times
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [
                next(0, "Success query 1"),
                next(searchDebounce + 1, "Success query 2")
            ])
    
            // Then
            testScheduler.start()
            XCTAssertEqual(stateObserver.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(firstResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce * 2 + 1, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce * 2 + 1, .found(secondResult.map { GiphyCellVM(item: $0) }))
            ])
        }
    }
    
    func test_loadingMore_whenLoadingNextPage_afterFoundState() {
        // Given
        let sut = makeSUT()
        let queryResult: [GiphyItem] = GiphyItem.createMocks(count: sut.pageSize)
        let nextPageResult: [GiphyItem] = GiphyItem.createMocks(count: 2)
        
        stubbedService.addSingleStub{ $0(.success(queryResult)) }
        stubbedService.addSingleStub{ $0(.success(nextPageResult)) }
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let stateObserver = registerStateListener(for: sut)
            
            // When
            /// Needs to fire query in specific times
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [next(0, "Success query 1")])
            
            /// Spoofs user scrool after initial search
            let _ = spoofInput(for: sut.indexPathWillBeShown, events: [next(searchDebounce + 1, IndexPath(row: queryResult.count - 1, section: 0))])
            
            // Then
            testScheduler.start()
            XCTAssertEqual(stateObserver.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(queryResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce + 1, .loadingMore(queryResult.map { GiphyCellVM(item: $0) },LoadingMoreCellVM())),
                .next(searchDebounce + 1, .found(
                        queryResult.map { GiphyCellVM(item: $0) } +
                        nextPageResult.map { GiphyCellVM(item: $0) }
                ))
            ])
        }
    }
    
    func test_loadingMore_returnsEmpty_afterFoundState() {
        // Given
        let sut = makeSUT()
        let queryResult: [GiphyItem] = GiphyItem.createMocks(count: sut.pageSize)
        
        stubbedService.addSingleStub{ $0(.success(queryResult)) }
        stubbedService.addSingleStub{ $0(.success([])) }
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let stateObserver = registerStateListener(for: sut)
            
            // When
            /// Needs to fire query in specific times
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [next(0, "Success query 1")])
            
            /// Spoofs user scrool after initial search
            let _ = spoofInput(for: sut.indexPathWillBeShown, events: [next(searchDebounce + 1, IndexPath(row: queryResult.count - 1, section: 0))])
            
            // Then
            testScheduler.start()
            XCTAssertEqual(stateObserver.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(queryResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce + 1, .loadingMore(queryResult.map { GiphyCellVM(item: $0) }, LoadingMoreCellVM())),
                .next(searchDebounce + 1, .found(queryResult.map { GiphyCellVM(item: $0) }))
            ])
        }
    }
    
    func test_loadingMore_scrollingToBottomMultipleTimes() {
        let n = 3 // Load more times
        // Given
        let sut = makeSUT()
        let queryResult: [GiphyItem] = GiphyItem.createMocks(count: sut.pageSize)
        stubbedService.addSingleStub{ $0(.success(queryResult)) }
        var nextPageResults: [[GiphyItem]] = []
        for _ in 1...n {
            let generated = GiphyItem.createMocks(count: sut.pageSize)
            nextPageResults.append(generated)
            stubbedService.addSingleStub { $0(.success(generated)) }
        }
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let stateObserver = registerStateListener(for: sut)

            // When
            /// Needs to fire query in specific time
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [next(0, "Success query 1")])
            
            /// Spoofs user scrool after initial search n times
            var userScroolEvents: [Recorded<Event<IndexPath>>] = []
            for i in 1...n {
                userScroolEvents.append(next(searchDebounce + 1 * i, IndexPath(row: sut.pageSize * i - 1, section: 0)))
            }
            
            let _ = spoofInput(for: sut.indexPathWillBeShown, events: userScroolEvents)
            
            // Then
            testScheduler.start()
            
            let initialfetchEvents: [Recorded<Event<GiphySearchState>>] = [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(queryResult.map { GiphyCellVM(item: $0) }))
            ]
            
            // TODO: Use n variable
            let expectedNewPageEvents: [Recorded<Event<GiphySearchState>>] = [
                .next(searchDebounce + 1, .loadingMore(queryResult.map { GiphyCellVM(item: $0) }, LoadingMoreCellVM())),
                .next(searchDebounce + 1, .found(
                        queryResult.map { GiphyCellVM(item: $0) } +
                        nextPageResults[0].map { GiphyCellVM(item: $0) }
                )),
                .next(searchDebounce + 2, .loadingMore(queryResult.map { GiphyCellVM(item: $0) } + nextPageResults[0].map { GiphyCellVM(item: $0) }, LoadingMoreCellVM())),
                .next(searchDebounce + 2, .found(
                        queryResult.map { GiphyCellVM(item: $0) } +
                        nextPageResults[0].map { GiphyCellVM(item: $0) } +
                        nextPageResults[1].map { GiphyCellVM(item: $0) }
                )),
                .next(searchDebounce + 3, .loadingMore(queryResult.map { GiphyCellVM(item: $0) } + nextPageResults[0].map { GiphyCellVM(item: $0) } + nextPageResults[1].map { GiphyCellVM(item: $0) }, LoadingMoreCellVM())),
                .next(searchDebounce + 3, .found(
                        queryResult.map { GiphyCellVM(item: $0) } +
                        nextPageResults[0].map { GiphyCellVM(item: $0) } +
                        nextPageResults[1].map { GiphyCellVM(item: $0) } +
                        nextPageResults[2].map { GiphyCellVM(item: $0) }
                ))
            ]
            
            XCTAssertEqual(stateObserver.events, initialfetchEvents + expectedNewPageEvents)
        }
    }
    
    func test_loadingMore_whenAlreadyLoadingNextPage() {
        // Given
        let sut = makeSUT()
        let queryResult: [GiphyItem] = GiphyItem.createMocks(count: sut.pageSize)
        
        stubbedService.addSingleStub { $0(.success(queryResult)) }
        stubbedService.addSingleStub() // Hangs on purpose
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = registerStateListener(for: sut)
            
            // When
            /// Needs to fire query in specific times
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [next(0, "Success query 1")])
            /// Spoofs user scrool after initial search
            let _ = spoofInput(for: sut.indexPathWillBeShown, events: [
                next(searchDebounce + 1, IndexPath(row: queryResult.count - 1, section: 0)),
                next(searchDebounce + 2, IndexPath(row: queryResult.count - 1, section: 0))
            ])
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(queryResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce + 1, .loadingMore(queryResult.map { GiphyCellVM(item: $0) }, LoadingMoreCellVM())),
            ])
        }
    }
    
    func test_loadingMore_isDisposed_whenPerformingQuery() {
        // Given
        let sut = makeSUT()
        let loadMoreDisposedExpectation = expectation(description: "Expectation for load more request to be canceled")
        let queryResult: [GiphyItem] = GiphyItem.createMocks(count: sut.pageSize)
        
        stubbedService.addSingleStub { $0(.success(queryResult)) }
        stubbedService.stubbedResults.append(Single<[GiphyItem]>.create(subscribe: { observer -> Disposable in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                XCTAssertEqual(loadMoreDisposedExpectation.expectedFulfillmentCount, 1)
            }
            return Disposables.create {
                loadMoreDisposedExpectation.fulfill()
            }
        }))

        stubbedService.addSingleStub { $0(.success(queryResult)) }
        
        SharingScheduler.mock(scheduler: testScheduler) {
            let observer = registerStateListener(for: sut)
            
            // When
            /// Needs to fire query in specific times
            let searchDebounce = sut.getSearchDebounce()
            let _ = spoofInput(for: sut.query, events: [
                next(0, "Success query 1"),
                next(searchDebounce + 2, "Success query 2")
            ])
            /// Spoofs user scrool after initial search
            let _ = spoofInput(for: sut.indexPathWillBeShown, events: [
                next(searchDebounce + 1, IndexPath(row: queryResult.count - 1, section: 0))
            ])
            
            // Then
            testScheduler.start()
            XCTAssertEqual(observer.events, [
                .next(0, .initial(InitialGiphyCellVM())),
                .next(searchDebounce, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce, .found(queryResult.map { GiphyCellVM(item: $0) })),
                .next(searchDebounce + 1, .loadingMore(queryResult.map { GiphyCellVM(item: $0) },LoadingMoreCellVM())),
                .next(searchDebounce * 2 + 2, .searching(SearchingGiphyCellVM())),
                .next(searchDebounce * 2 + 2, .found(queryResult.map { GiphyCellVM(item: $0) }))
            ])
            
            waitForExpectations(timeout: 3)
        }
    }
    
    // MARK: Helpers
    
    private func makeSUT() -> TDDGiphySearchVM {
        return TDDGiphySearchVM(giphyService: stubbedService)
    }
    
    func registerStateListener(for sut: TDDGiphySearchVM) -> TestableObserver<GiphySearchState> {
        let observer = testScheduler.createObserver(GiphySearchState.self)
        sut.stateRelay.bind(to: observer).disposed(by: bag)
        return observer
    }
    
    func spoofInput<T>(for observer: BehaviorRelay<T>, events: [Recorded<Event<T>>]) -> TestableObservable<T> {
        let spoofUserInput = testScheduler.createHotObservable(events)
        spoofUserInput.bind(to: observer).disposed(by: bag)
        return spoofUserInput
    }
    
    func spoofInput<T>(for observer: PublishRelay<T>, events: [Recorded<Event<T>>]) -> TestableObservable<T> {
        let spoofUserInput = testScheduler.createHotObservable(events)
        spoofUserInput.bind(to: observer).disposed(by: bag)
        return spoofUserInput
    }
}




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
    
    func addSingleStub(onSubscribe: (((SingleEvent<Array<GiphyItem>>) -> ())->Void)? = nil) {
        let single = Single<[GiphyItem]>.create { (observer) -> Disposable in
            onSubscribe?(observer)
            return Disposables.create()
        }
        stubbedResults.append(single)
    }
}

extension GiphyItem {
    static func createMocks(count: Int = 1)  -> [GiphyItem] {
        var generated: [GiphyItem] = []
        for _ in 0...count - 1 {
            generated.append(.init(id: UUID().uuidString,
                                   image: Image(height: "",
                                                width: "",
                                                url: URL(string: "www.someurl.lv")!)))
        }
        return generated
    }
}
