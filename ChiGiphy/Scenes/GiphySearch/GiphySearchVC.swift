//
//  GiphySearchVC.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Cartography

final class GiphySearchVC: UIViewController {
    
    // MARK: Vars
    
    private var gifCollectionView: UICollectionView!
    
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>!
    
    private let viewModel: GiphySearchVMProtocol
    
    private let bag = DisposeBag()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: Init
    
    init(viewModel: GiphySearchVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureNavigationBar()
        setupCollectionView()
        configureDataSource()
        bindToViewModel()
    }
    
    private func configureNavigationBar() {
        title = viewModel.title
        configureSearchBar()
    }
    
    private func configureSearchBar() {
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        navigationItem.searchController = searchController
    }
    
    private func configureView() {
        view.backgroundColor = UIColor.PrimaryBackground
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
            viewModel.stateOutput
            .asObservable()
            .debounce(0.1, scheduler: MainScheduler.instance)
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
        
        // Scrolls to top to reset state between searches - better to provide empty array though
        viewModel.stateOutput.asObservable().scan([]) { (previous, current) in
            Array(previous + [current]).suffix(2)
        }.subscribe(onNext: { [unowned self] (lastStates) in
            if case .searching(_) = lastStates[0],  case .found(_) = lastStates[1] {
                gifCollectionView.scrollToItem(at: .init(row: 0, section: 0), at: .top, animated: true)
            }
        }).disposed(by: bag)
        
        searchController.searchBar.rx.text.orEmpty.bind(to: viewModel.queryInput).disposed(by: bag)
        
        gifCollectionView.rx.willDisplayCell.map { $1 }.skip(1)
            .bind(to: viewModel.indexPathWillBeShownInput)
            .disposed(by: bag)
        
        viewModel.errorOutput.asObservable().subscribe(onNext: { error in
            InfoView.showIn(viewController: self, message: error.localizedDescription)
        }).disposed(by: bag)
        
        viewModel.isRechableOutput.asObservable().subscribe(onNext: { isReachable in
            if isReachable {
                InfoView.sharedView?.fadeOut()
            } else {
                InfoView.showIn(viewController: self, message: ReachabilityError.disconnected.localizedDescription)
            }
            
        }).disposed(by: bag)
    }
    

    
    private func setupCollectionViewLayout() {
        let layout = CHTCollectionViewWaterfallLayout()
        gifCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        layout.delegate = self
        layout.minimumColumnSpacing = 3.0
        layout.minimumInteritemSpacing = 3.0
        gifCollectionView.collectionViewLayout = layout
        gifCollectionView.alwaysBounceVertical = true
    }
    
    private func setupCollectionView() {
        setupCollectionViewLayout()
        registerCollectionViewCells()
        gifCollectionView.backgroundColor = UIColor.PrimaryBackground
        gifCollectionView.showsVerticalScrollIndicator = false
        view.addSubview(gifCollectionView)
        constrain(gifCollectionView, view.safeAreaLayoutGuide) { $0.edges == $1.edges }
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

extension GiphySearchVC: CHTCollectionViewDelegateWaterfallLayout  {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch viewModel.getCurrentState() {
        case .loadingMore(let vms, _), .found(let vms):
            if indexPath.section == GiphyColletionViewSection.loading.rawValue {
                return CGSize(width: collectionView.bounds.width, height: 44)
            }
            return vms[indexPath.row].size
        default:
            return collectionView.bounds.size
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        switch viewModel.getCurrentState() {
        case .found(_), .loadingMore(_, _):
            return section == GiphyColletionViewSection.giphyList.rawValue ? 2 : 1
        default:
            return 1
        }
    }
}

fileprivate enum GiphyColletionViewSection: Int {
    case giphyList = 0
    case loading
}

fileprivate typealias GiphySection = AnimatableSectionModel<String, CellViewModel>

fileprivate enum CellViewModel: Equatable, IdentifiableType {
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
