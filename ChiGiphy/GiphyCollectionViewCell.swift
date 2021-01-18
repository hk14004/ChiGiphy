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
    
    private var readyToAnimate = false {
        didSet {
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
    }
    
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
        disposable.dispose()
        disposable = SingleAssignmentDisposable()
    }
    
    private func setupHearchy() {
        contentView.addSubview(activityIndicator)
        contentView.addSubview(giphyImageView)
    }
    
    func setup(with item: GiphyItem) {
        self.downloadAndDisplay(gif: item.image.url)
    }
    
    var disposable = SingleAssignmentDisposable()
    
    func downloadAndDisplay(gif url: URL) {
      let request = URLRequest(url: url)
        readyToAnimate = false

      let s = URLSession.shared.rx.data(request: request)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] imageData in
          guard let self = self else { return }

            self.giphyImageView.prepareForAnimation(withGIFData: imageData, loopCount: 0) {
                //print("ready to animate")
                DispatchQueue.main.async {
                    self.readyToAnimate = true
                }
            }
        })

      disposable.setDisposable(s)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
