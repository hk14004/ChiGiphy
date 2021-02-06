//
//  NotFoundGiphyCollectionViewCell.swift
//  ChiGiphy
//
//  Created by Hardijs on 06/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Cartography

class NotFoundGiphyCollectionViewCell: UICollectionViewCell {
   
    // MARK: Vars
    
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
