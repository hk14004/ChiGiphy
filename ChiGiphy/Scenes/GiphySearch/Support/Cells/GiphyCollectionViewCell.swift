//
//  GiphyCollectionViewCell.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit
import Gifu
import RxSwift
import Cartography

class GiphyCollectionViewCell: UICollectionViewCell {
    
    // MARK: Vars
    
    private let giphyImageView = GIFImageView()
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private var bag = DisposeBag()
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHearchy()
        setupViews()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    private func setupViews() {
        contentView.backgroundColor = UIColor.PrimaryBackground
        activityIndicator.hidesWhenStopped = true
        giphyImageView.contentMode = .scaleAspectFit
    }
    
    private func setupLayout() {
        constrain(giphyImageView, contentView) { $0.edges == $1.edges }
        constrain(activityIndicator, contentView) {
            $0.centerY == $1.centerY
            $0.centerX == $1.centerX
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        giphyImageView.prepareForReuse()
        giphyImageView.updateImageIfNeeded()
        bag = DisposeBag()
    }
    
    private func setupHearchy() {
        contentView.addSubview(activityIndicator)
        contentView.addSubview(giphyImageView)
    }
    
    private func changeState(readyToAnimate: Bool) {
        if readyToAnimate {
            activityIndicator.stopAnimating()
            giphyImageView.startAnimatingGIF()
            UIView.animate(withDuration: 0.3) {
                self.giphyImageView.isHidden = !readyToAnimate
                self.giphyImageView.alpha = 1
            }
        } else {
            activityIndicator.startAnimating()
            giphyImageView.stopAnimatingGIF()
            giphyImageView.alpha = 0
        }
    }
    
    func setup(with viewModel: GiphyCellVMProtocol) {
        viewModel.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[unowned self] state in
            switch state {
            case .initial, .downloading:
                changeState(readyToAnimate: false)
            case .downloaded(let gifData):
                prepareForAnimation(with: gifData)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        changeState(readyToAnimate: true)
                }).disposed(by: bag)
            }
        }).disposed(by: bag)
    }
        
    private func prepareForAnimation(with gifData: Data) -> Observable<Void> {
        return Observable.create { observer in
            self.giphyImageView.prepareForAnimation(withGIFData: gifData, loopCount: 0) {
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
