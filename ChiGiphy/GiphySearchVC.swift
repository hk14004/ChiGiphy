//
//  GiphySearchVC.swift
//  ChiGiphy
//
//  Created by Hardijs on 08/01/2021.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa

typealias GiphySection = AnimatableSectionModel<String, GiphyItem>

class GiphySearchVC: UIViewController {
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>?
    
    private let disposeBag = DisposeBag()
    
    private let viewModel: GiphySearchVM
    
    private let gifCollectionView = UICollectionView(frame: CGRect(),
                                                     collectionViewLayout: createLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureDataSource()
        bindToViewModel()
        setupCollectionView()
        viewModel.load()
    }
    
    private func setupNavigationBar() {
        title = "Giphy Searcher"
        navigationItem.hidesSearchBarWhenScrolling = false
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        //searchController.searchResultsUpdater = self.viewModel
        searchController.searchBar.text = "warzone"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search gif"
        navigationItem.searchController = searchController
    }
    
    private func bindToViewModel() {
        guard let searchBar = navigationItem.searchController?.searchBar else { return }
        searchBar.rx.text.orEmpty.bind(to: viewModel.searchQuery).disposed(by: self.disposeBag)
        
        guard let dataSource = dataSource else { return }
        
        viewModel.sectionData.drive(gifCollectionView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag)
        
//        viewModel.sectionData
//            .bind(to: gifCollectionView.rx.items(dataSource: dataSource))
//            .disposed(by: self.disposeBag)
        
        gifCollectionView.rx.willDisplayCell.map { $1 }
            .bind(to: viewModel.contentWillBeShownAt)
            .disposed(by: self.disposeBag)
    }
    
    private func configureDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<GiphySection>(
            configureCell: {
                (dataSource, collectionView, indexPath, item) -> UICollectionViewCell in
                let cell: GiphyCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setup(with: item)
                return cell
            })
    }
    
    private func setupCollectionView() {
        gifCollectionView.register(GiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: GiphyCollectionViewCell.reuseIdentifier)
        gifCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gifCollectionView)
        gifCollectionView.backgroundColor = UIColor(named: "Background")
        // TODO: Provide exension with single call
        NSLayoutConstraint.activate([
            gifCollectionView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            gifCollectionView.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            gifCollectionView.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            gifCollectionView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: Init
    
    required init(viewModel: GiphySearchVM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static private func createLayout() -> UICollectionViewLayout {
        let size: CGFloat = 1/2
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(size), heightDimension: .fractionalWidth(size))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
