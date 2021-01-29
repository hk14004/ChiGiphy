////
////  Scrabble.swift
////  ChiGiphyTests
////
////  Created by Hardijs on 29/01/2021.
////
//
//import XCTest
//import RxTest
//import RxBlocking
//import RxSwift
//import RxCocoa
//import RxDataSources
//@testable import ChiGiphy
//
//func test_Nothing() {
//    let stubbedService = StubbedGiphyService()
//    let bag = DisposeBag()
//    enum CellViewModel: Equatable, IdentifiableType {
//        case found(GiphyCellVM)
//        case notFound(NotFoundGiphyCellVM)
//        case initial(InitialGiphyCellVM)
//            
//        var identity: String {
//            switch self {
//            case .found(let vm): return vm.identity
//            case .notFound(let vm): return vm.identity
//            case .initial(let vm): return vm.identity
//            }
//        }
//        
//    }
//    typealias Section = AnimatableSectionModel<String, CellViewModel>
//    let sut = GiphySearchVM(giphyService: stubbedService)
//    sut.state.subscribe(onNext: { state in
//        switch state {
//        case .found(let gifsVMs):
//            print(gifsVMs)
//        case .notFound(let notFoundVM):
//            print(notFoundVM)
//        case .initial(let initialCellVM):
//            print(initialCellVM)
//        case .searching(let vm):
//            print(vm)
//        }
//    }).disposed(by: bag)
//    
//    let ds = RxCollectionViewSectionedAnimatedDataSource<Section> {(ds, gg, ff, aa) -> UICollectionViewCell in
//        switch aa {
//        case .found(let vm):
//            let cell = UICollectionViewCell()
//            //cell.setup
//            return cell
//        case .notFound(let vm):
//            let cell = UICollectionViewCell()
//            //cell.setup
//            return cell
//        case .initial(let vm):
//            let cell = UICollectionViewCell()
//            //cell.setup
//            return cell
//        }
//    }
//}
