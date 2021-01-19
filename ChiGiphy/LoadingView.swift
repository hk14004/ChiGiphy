//
//  LoadingView.swift
//  ChiGiphy
//
//  Created by Hardijs on 18/01/2021.
//

import UIKit
import RxCocoa
import RxSwift
import NVActivityIndicatorView
import Cartography

class LoadingView: UICollectionReusableView {
    
    private let disposeBag = DisposeBag()
    
    private lazy var activityIndicator = NVActivityIndicatorView(frame: bounds,
                                                                 type: .ballPulse,
                                                                 color: .purple,
                                                                 padding: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
     }

    private func setupLayout() {
        addSubview(activityIndicator)
        constrain(activityIndicator, self) { ac, view in
            ac.edges == view.edges
        }
    }
    
    private func changeState(isHidden: Bool) {
        if isHidden {
            activityIndicator.stopAnimating()
        } else {
            activityIndicator.startAnimating()
        }
        
        self.isHidden = isHidden
    }
    
     required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
     }
    
    func setup(with viewModel: GiphySearchVM) {
        viewModel.isLoading.drive(onNext: { [weak self] isLoading in
            self?.changeState(isHidden: !isLoading)
        }).disposed(by: disposeBag)
    }
}

extension LoadingView: ReusableViewProtocol {}
