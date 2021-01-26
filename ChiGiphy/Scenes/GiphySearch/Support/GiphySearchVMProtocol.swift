//
//  GiphySearchVMProtocol.swift
//  ChiGiphy
//
//  Created by Hardijs on 27/01/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol GiphySearchVMProtocol {
    var title: String { get }
    var sectionData: Driver<[GiphySection]> { get }
    var indexPathWillBeShown: AnyObserver<IndexPath> { get }
    var gifColumns: Int { get }
    var loadingObservable: Observable<Bool> { get }
    func getGifSize(at indexPath: IndexPath) -> CGSize
}
