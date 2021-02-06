//
//  InitialGiphyCollectionViewCell.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import UIKit
import Cartography
import NVActivityIndicatorView

class InitialGiphyCollectionViewCell: UICollectionViewCell {
   
    // MARK: Vars
    
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
