//
//  GenericSearchVC.swift
//  ChiGiphy
//
//  Created by Hardijs on 18/01/2021.
//

import UIKit
import RxSwift
import RxCocoa

class GenericSearchVC<T>: UIViewController {
    
    // MARK: Variables
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let genericSearchVM: GenericSearchVM<T>
    
    private let disposeBag = DisposeBag()
    
    var errorView: UIView? {
        return nil
    }
    
    var loadingView: UIView? {
        return nil
    }
    
    // MARK: Init
    
    init(viewModel: GenericSearchVM<T>) {
        self.genericSearchVM = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBar()
        bindViews()
        
        // initial state
        errorView?.isHidden = true
        loadingView?.isHidden = true
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
    
    private func bindViews() {
        searchController.searchBar
            .rx
            .text
            .orEmpty
            .bind(to: genericSearchVM.searchQueryRelay)
            .disposed(by: disposeBag)
        
        if let loadingView = loadingView {
            genericSearchVM.loadingObservable
                .asDriver(onErrorJustReturn: true)
                .map(!)
                .drive(loadingView.rx.isHidden)
                .disposed(by: disposeBag)
            
            genericSearchVM.errorDriver
                .map { $0 != nil }
                .drive(loadingView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        if let errorView = errorView {
            genericSearchVM.errorDriver
                .map { $0 == nil }
                .drive(errorView.rx.isHidden)
                .disposed(by: disposeBag)
        }
    }
}
