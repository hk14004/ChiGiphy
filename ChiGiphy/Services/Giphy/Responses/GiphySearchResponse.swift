//
//  GiphySearchResponse.swift
//  ChiGiphy
//
//  Created by Hardijs on 01/03/2021.
//

import Foundation

struct GiphySearchResponse: Decodable {
    let data: LossyDecodableArray<GiphyItem>
}

struct Pagination: Decodable {
    let total_count: Int
    let count: Int
    let offset: Int
}
