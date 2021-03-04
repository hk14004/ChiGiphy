//
//  GiphyQueryableFeed.swift
//  ChiliGiphy
//
//  Created by Hardijs on 17/02/2021.
//  Copyright © 2021 Chili Labs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftExt

class GiphyQueryableFeed: GenericQueryableFeed {
    var feedSize: Int = 0

    let pageSize: Int
    
    var latestQuery: String?
    
    private let service: GiphyServiceProtocol

    init(service: GiphyServiceProtocol = GiphyService(), pageSize: Int = 20) {
        self.service = service
        self.pageSize = pageSize
    }

    func search(query: String) -> Observable<[GiphyItem]> {
        service.search(text: query, offset: 0, limit: pageSize).do(onNext: { [unowned self] items in
            latestQuery = query
            feedSize = items.count
        })
    }

    func getNextPage() -> Observable<[GiphyItem]> {
        guard let query = latestQuery else { return .just([]) }
        return service.search(text: query, offset: feedSize + 1, limit: pageSize).do(onNext: { [unowned self] items in
            feedSize += items.count
        })
    }
}
