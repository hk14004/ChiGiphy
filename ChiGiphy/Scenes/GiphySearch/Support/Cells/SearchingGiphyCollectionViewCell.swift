//
//  SearchingGiphyCollectionViewCell.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import UIKit
import NVActivityIndicatorView
import Cartography

class SearchingGiphyCollectionViewCell: UICollectionViewCell {
   
    // MARK: Vars
    
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
        contentView.addSubview(activityIndicator)
        constrain(activityIndicator, contentView) { ac, view in
            ac.center == view.center
            ac.height == 100
            ac.width == 100
        }
    }
}
