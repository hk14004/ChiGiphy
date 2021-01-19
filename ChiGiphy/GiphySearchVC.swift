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
import Cartography

typealias GiphySection = AnimatableSectionModel<String, GiphyItem>

class GiphySearchVC: GenericSearchVC<GiphyItem> {
    
    private let disposeBag = DisposeBag()
    
    private let viewModel: GiphySearchVM
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>?
    
    private let gifCollectionView = UICollectionView(frame: CGRect(),
                                                     collectionViewLayout: createLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        bindToViewModel()
    }
    
    // MARK: Init
    
    required init(viewModel: GiphySearchVM) {
        self.viewModel = viewModel
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNavigationBar() {
        title = viewModel.title
    }
    
    private func bindToViewModel() {
        if let dataSource = dataSource {
            viewModel.sectionData.drive(
                gifCollectionView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag
                )
        } else {
            fatalError("No data source")
        }
        
        gifCollectionView.rx.willDisplayCell.map { $1 }
            .bind(to: viewModel.indexPathWillBeShown)
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
        
        dataSource?.configureSupplementaryView = {(dataSource, collectionView, kind, indexPath) in
            switch kind {
            case UICollectionElementKindSectionFooter:
                let footerLoadingView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter,
                                                                                        withReuseIdentifier: LoadingView.reuseIdentifier,
                                                                                        for: indexPath) as! LoadingView
                footerLoadingView.setup(with: self.viewModel)
                return footerLoadingView
            default:
                fatalError("Unexpected element kind: \(kind)")
            }
        }
    }
    
    private func registerCollectionViewCells() {
        gifCollectionView.register(LoadingView.self,
                                   forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                                   withReuseIdentifier: LoadingView.reuseIdentifier)
        gifCollectionView.register(GiphyCollectionViewCell.self,
                                   forCellWithReuseIdentifier: GiphyCollectionViewCell.reuseIdentifier)
    }
    
    private func setupCollectionView() {
        registerCollectionViewCells()
        gifCollectionView.backgroundColor = UIColor(named: "Background")
        view.addSubview(gifCollectionView)
        constrain(gifCollectionView, view) { $0.edges == $1.edges }
        configureDataSource()
    }
        
    //TODO: Improve layout with aspect fit width and height
    static private func createLayout() -> UICollectionViewLayout {
        let gifSize: CGFloat = 1/2
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(gifSize), heightDimension: .fractionalWidth(gifSize))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 2,
                                                     leading: 2,
                                                     bottom: 2,
                                                     trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionElementKindSectionFooter, alignment: .bottom)
        section.boundarySupplementaryItems = [footerItem]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
