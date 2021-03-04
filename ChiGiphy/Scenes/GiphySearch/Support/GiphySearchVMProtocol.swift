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

    //MARK: Vars
    
    /// Load new page when x elements left to display
    var loadWhenItemsLeft: Int { get }
    
    /// Query input interval
    var queryDebounce: Double { get }
    
    // MARK: Input

    var indexPathWillBeShownInput: AnyObserver<IndexPath> { get }
    var queryInput: AnyObserver<String> { get }
    
    // MARK: Output
    
    var stateOutput: Observable<GiphySearchState> { get }
    
    var errorOutput: Observable<Error> { get }
    
    // MARK: Methods
    
    func getCurrentState() -> GiphySearchState
}
