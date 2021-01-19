//
//  GiphyCollectionViewCell.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit
import Gifu
import RxSwift

class GiphyCollectionViewCell: UICollectionViewCell {
    
    private let giphyImageView = GIFImageView()
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private var viewModel: GiphyCollectionViewCellVM?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHearchy()
        setupViews()
        setupLayout()
        contentView.backgroundColor = UIColor(named: "Background")
    }
    
    func setupViews() {
        activityIndicator.hidesWhenStopped = true
        [giphyImageView, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func setupLayout() {
        NSLayoutConstraint.activate([
            giphyImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            giphyImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            giphyImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            giphyImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        giphyImageView.prepareForReuse()
        giphyImageView.updateImageIfNeeded()
        disposables.forEach { $0.dispose() }
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
        
        let g = viewModel.isLoading.drive(onNext: { isLoading in
            self.changeState(readyToAnimate: !isLoading)
        })
        disposables.append(g)
        
        let gg = viewModel.gifDataSubject.subscribe(onNext: { (data) in
            let ggg = self.prepareForAnimation(with: data).subscribe(onCompleted: {
                viewModel.preparingForAnimation.onNext(false)
            })
            self.disposables.append(ggg)
        })
        disposables.append(gg)
        viewModel.download()
    }
        
    var disposables:[Disposable] = []
    func prepareForAnimation(with gifData: Data) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            DispatchQueue.main.async {
                self?.giphyImageView.prepareForAnimation(withGIFData: gifData, loopCount: 0) {
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
