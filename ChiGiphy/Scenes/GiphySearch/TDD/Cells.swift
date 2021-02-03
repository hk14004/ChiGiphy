//
//  Cells.swift
//  ChiGiphy
//
//  Created by Hardijs on 03/02/2021.
//

import UIKit
import Cartography
import NVActivityIndicatorView

class InitialGiphyCollectionViewCell: UICollectionViewCell {
   
    private let label: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("Try to search something!", comment: "")
        l.textAlignment = .center
        return l
    }()
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    private func setupViews() {
        contentView.addSubview(label)
        constrain(label, contentView) { $0.edges == $1.edges }
    }
}

class SearchingGiphyCell: UICollectionViewCell {
   
    private lazy var activityIndicator = NVActivityIndicatorView(frame: bounds,
                                                                 type: .ballGridPulse,
                                                                 color: .purple,
                                                                 padding: 0)
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    private func setupViews() {
        // Setup
        activityIndicator.startAnimating()
        
        // Layout
        addSubview(activityIndicator)
        constrain(activityIndicator, self) { ac, view in
            ac.center == view.center
            ac.height == 100
            ac.width == 100
        }
    }
}

class NotFoundGiphyCollectionViewCell: UICollectionViewCell {
   
    private let imageView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "photo.fill.on.rectangle.fill"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("No GIFs found!", comment: "")
        l.textAlignment = .center
        return l
    }()
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    private func setupViews() {
        let stackView   = UIStackView()
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.alignment = UIStackView.Alignment.center

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
      contentView.addSubview(stackView)
        constrain(stackView, contentView) {
            $0.center == $1.center
        }
        
        constrain(imageView) {
            $0.width == 100
            $0.height == 100
        }
    }
}

class LoadingMoreGiphyCell: UICollectionViewCell {
   
    private lazy var activityIndicator = NVActivityIndicatorView(frame: bounds,
                                                                 type: .ballPulse,
                                                                 color: .purple,
                                                                 padding: 0)
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    
    private func setupViews() {
        // Setup
        activityIndicator.startAnimating()
        
        // Layout
        contentView.addSubview(activityIndicator)
        constrain(activityIndicator, contentView) { ac, view in
            ac.edges == view.edges
        }
    }
}
