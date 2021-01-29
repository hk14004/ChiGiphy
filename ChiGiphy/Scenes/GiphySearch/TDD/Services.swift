//
//  Services.swift
//  ChiGiphy
//
//  Created by Hardijs on 29/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol GiphyServiceProtocol {
    func search(text: String, offset: Int, limit: Int) -> Single<[GiphyItem]>
}

