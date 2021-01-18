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
    
    private let _loadingView: UIView = {
        let view = UIView(frame: .zero)
        let label = UILabel(frame: .zero)
        label.text = "Loading..."
        label.textAlignment = .center
        view.addSubview(label)
        constrain(label) { label in
            label.edges == label.superview!.edges
        }
        return view
    }()
    
    override var loadingView: UIView? {
        return _loadingView
    }
    
    private let disposeBag = DisposeBag()
    
    private let viewModel: GiphySearchVM
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>?
    
    private let gifCollectionView = UICollectionView(frame: CGRect(),
                                                     collectionViewLayout: createLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureDataSource()
        bindToViewModel()
        setupCollectionView()
        setupLoadingView()
    }
    
    private func setupLoadingView() {
        view.addSubview(loadingView!)
        constrain(loadingView!) { (loading) in
            loading.edges == loading.superview!.edges
        }
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
        super.init(viewModel: viewModel)
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
