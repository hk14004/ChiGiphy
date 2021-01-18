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

    private let searchController = UISearchController(searchResultsController: nil)
    
    private let genericSearchVM: GenericSearchVM<T>

    private let disposeBag = DisposeBag()
    
    var errorView: UIView? {
        return nil
    }

    var loadingView: UIView? {
        return nil
    }

    init(viewModel: GenericSearchVM<T>) {
        self.genericSearchVM = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
          .bind(to: self.genericSearchVM.searchObserver)
          .disposed(by: disposeBag)

          if let loadingView = loadingView {
              genericSearchVM.isLoading
                  .map(!)
                  .drive(loadingView.rx.isHidden)
                  .disposed(by: disposeBag)
              genericSearchVM.error
                  .map { $0 != nil }
                  .drive(loadingView.rx.isHidden)
                  .disposed(by: disposeBag)
          }

          if let errorView = errorView {
              genericSearchVM.error
                  .map { $0 == nil }
                  .drive(errorView.rx.isHidden)
                  .disposed(by: disposeBag)
          }
      }
}
