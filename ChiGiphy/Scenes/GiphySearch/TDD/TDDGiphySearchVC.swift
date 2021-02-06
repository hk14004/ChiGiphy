//
//  TDDGiphySearchVC.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Cartography
import SCLAlertView

final class TDDGiphySearchVC: UIViewController {
    
    // MARK: Types
    
    typealias GiphySection = AnimatableSectionModel<String, CellViewModel>
    
    enum CellViewModel: Equatable, IdentifiableType {
        case found(GiphyCellVM)
        case notFound(NotFoundGiphyCellVM)
        case initial(InitialGiphyCellVM)
        case searching(SearchingGiphyCellVM)
        case loadingMore(LoadingMoreCellVM)
        
        var identity: String {
            switch self {
                case .found(let vm): return vm.identity
                case .notFound(let vm): return vm.identity
                case .initial(let vm): return vm.identity
                case .searching(let vm): return vm.identity
                case .loadingMore(let vm): return vm.identity
            }
        }
    }
    
    // MARK: Vars
    
    private var gifCollectionView: UICollectionView!
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>!
    
    let viewModel: TDDGiphySearchVM // TODO: Protocol
    
    let bag = DisposeBag()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: Init
    
    init(viewModel: TDDGiphySearchVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBar()
        setupCollectionView()
        configureDataSource()
        bindToViewModel()
    }
    
    private func configureDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<GiphySection> {(source, cv, indexPath, cell) -> UICollectionViewCell in
            switch cell {
                case .initial(_):
                    let cell: InitialGiphyCollectionViewCell = cv.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                case .notFound(_):
                    let cell: NotFoundGiphyCollectionViewCell = cv.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                case .found(let vm):
                    let cell: GiphyCollectionViewCell = cv.dequeueReusableCell(forIndexPath: indexPath)
                    //cell.setup(with: GiphyCellVM(item: vm.item))
                    cell.setup(with: vm)
                    return cell
                case .searching(_):
                    let cell: SearchingGiphyCollectionViewCell = cv.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                case .loadingMore(_):
                    let cell: LoadingMoreGiphyCell = cv.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
            }
        }
    }


    private func bindToViewModel() {
        let sections: Observable<[GiphySection]> =
            viewModel.stateRelay
            .map({ state in
            switch state {
                case .found(let gifsVMs):
                    return [GiphySection(model: "Found", items: gifsVMs.map { CellViewModel.found($0)})]
                case .notFound(let notFoundVM):
                    return [GiphySection(model: "Not Found", items: [.notFound(notFoundVM)])]
                case .initial(let initialCellVM):
                    return [GiphySection(model: "init", items: [.initial(initialCellVM)])]
                case .searching(let vm):
                    return [GiphySection(model: "Searching", items: [.searching(vm)])]
                case .loadingMore(let gifsVMs, let loadingVM):
                    return [GiphySection(model: "Found", items: gifsVMs.map { CellViewModel.found($0)} ),
                            GiphySection(model: "Loadinng", items: [.loadingMore(loadingVM)] )
                    ]
                }
        })
                
        sections.bind(to: gifCollectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        
        searchController.searchBar
            .rx
            .text
            .orEmpty
            .bind(to: viewModel.query)
            .disposed(by: bag)
        
        gifCollectionView.rx.willDisplayCell.map { $1 }
            .bind(to: viewModel.indexPathWillBeShown)
            .disposed(by: bag)
    }
    
    private func configureSearchBar() {
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.text = ""
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        navigationItem.searchController = searchController
    }
    
    private func setupCollectionViewLayout() {
        let layout = CHTCollectionViewWaterfallLayout()
        gifCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.delegate = self
        layout.minimumColumnSpacing = 3.0
        layout.minimumInteritemSpacing = 3.0
        gifCollectionView.collectionViewLayout = layout
    }
    
    private func setupCollectionView() {
        setupCollectionViewLayout()
        registerCollectionViewCells()
        gifCollectionView.backgroundColor = UIColor.PrimaryBackground
        view.addSubview(gifCollectionView)
        constrain(gifCollectionView, view) { $0.edges == $1.edges }
    }
    
    private func registerCollectionViewCells() {
        gifCollectionView.register(GiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: GiphyCollectionViewCell.reuseIdentifier)
        gifCollectionView.register(InitialGiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: InitialGiphyCollectionViewCell.reuseIdentifier)
        gifCollectionView.register(SearchingGiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: SearchingGiphyCollectionViewCell.reuseIdentifier)
        gifCollectionView.register(NotFoundGiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: NotFoundGiphyCollectionViewCell.reuseIdentifier)
        gifCollectionView.register(LoadingMoreGiphyCell.self,
                                   forCellWithReuseIdentifier: LoadingMoreGiphyCell.reuseIdentifier)
    }
}

extension TDDGiphySearchVC: CHTCollectionViewDelegateWaterfallLayout  {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch viewModel.stateRelay.value {
        case .found(let vms):
            return vms[indexPath.row].size
        case .loadingMore(let vms, _):
            if indexPath.section == 1 {
                return CGSize(width: collectionView.bounds.width, height: 50)
            }
            return vms[indexPath.row].size
        default:
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height - (self.navigationController?.navigationBar.frame.size.height ?? 0))
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        switch viewModel.stateRelay.value {
        case .found(_), .loadingMore(_, _):
            return section == 0 ? 2 : 1
        default:
            return 1
        }
    }
}
