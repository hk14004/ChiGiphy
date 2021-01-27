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
import SCLAlertView

typealias GiphySection = AnimatableSectionModel<String, GiphyItem>

class GiphySearchVC: GenericSearchVC<GiphyItem> {
    
    private let disposeBag = DisposeBag()
    
    private let viewModel: GiphySearchVMProtocol
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<GiphySection>!
    
    private var gifCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        bindToViewModel()
    }
    
    // MARK: Init
    
    required init(viewModel: (GiphySearchVMProtocol & GenericSearchVM<GiphyItem>)) {
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
            viewModel.sectionData.drive(
                gifCollectionView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag
            )
        
        gifCollectionView.rx.willDisplayCell.map { $1 }
            .bind(to: viewModel.indexPathWillBeShown)
            .disposed(by: self.disposeBag)
        
        viewModel.errorDriver.asObservable().subscribe(onNext: { error in
            guard let error = error else {  return}
            switch error {
            case .underlyingError(let error):
                SCLAlertView().showError(NSLocalizedString("Error occured", comment: ""),
                                         subTitle: error.localizedDescription)
            case .notFound:
                SCLAlertView().showWarning(NSLocalizedString("No results found", comment: ""),
                                           subTitle: NSLocalizedString("Try to search for something else", comment: ""))
            case .unknown:
                SCLAlertView().showError(NSLocalizedString("Unknown error occured", comment: ""),
                                         subTitle: "")
            }
        }).disposed(by: disposeBag)
    }
    
    private func configureDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<GiphySection>(
            configureCell: {
                (dataSource, collectionView, indexPath, item) -> UICollectionViewCell in
                let cell: GiphyCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setup(with: GiphyCollectionViewCellVM(gifItem: item))
                return cell
            })
        
        dataSource.configureSupplementaryView = {(dataSource, collectionView, kind, indexPath) in
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
        configureDataSource()
        gifCollectionView.backgroundColor = UIColor.PrimaryBackground
        view.addSubview(gifCollectionView)
        constrain(gifCollectionView, view) { $0.edges == $1.edges }
    }
}

extension GiphySearchVC: CHTCollectionViewDelegateWaterfallLayout  {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return viewModel.getGifSize(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        return viewModel.gifColumns
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForFooterIn section: Int) -> CGFloat {
        return 44
    }
}
