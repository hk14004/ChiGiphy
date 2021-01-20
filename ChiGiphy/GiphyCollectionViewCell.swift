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
    
    private let giphyImageView = GIFImageView()
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private var bag = DisposeBag()
    
    private var viewModel: GiphyCollectionViewCellVM?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHearchy()
        setupViews()
        setupLayout()
    }
    
    func setupViews() {
        contentView.backgroundColor = UIColor.PrimaryBackground
        activityIndicator.hidesWhenStopped = true
    }
    
    func setupLayout() {
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
            giphyImageView.isHidden = false
        } else {
            activityIndicator.startAnimating()
            giphyImageView.stopAnimatingGIF()
            giphyImageView.isHidden = true
        }
    }
    
    func setup(with viewModel: GiphyCollectionViewCellVM) {
        self.viewModel = viewModel
        
        viewModel.isLoadingDriver.drive(onNext: { isLoading in
            self.changeState(readyToAnimate: !isLoading)
        }).disposed(by: bag)


        viewModel.loadGifData().flatMapLatest { (data)  in
            return self.prepareForAnimation(with: data)
        }.bind(to: viewModel.isLoadingObserver)
        .disposed(by: bag)
    }
        
    func prepareForAnimation(with gifData: Data) -> Observable<Bool> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                self.giphyImageView.prepareForAnimation(withGIFData: gifData, loopCount: 0) {
                    observer.onNext(false)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
