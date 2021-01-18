//
//  GiphyService.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import Foundation
import RxSwift

struct GiphySearchResponse: Decodable {
    let data: [GiphyItem]
    //let pagination: Pagination
}

struct Pagination: Decodable {
    let total_count: Int
    let count: Int
    let offset: Int
}

class GiphyService {
    static let shared = GiphyService()
    private let apiKey = "X09nb1IgWr4u7dxoMJbZ8iQs3ClrlAM0"
        
    func search(text: String, offset: Int = 0, limit: Int = 20) -> Observable<[GiphyItem]> {
        let url = URL(string: "http://api.giphy.com/v1/gifs/search")!
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "api_key", value: apiKey)
        let searchQueryItem = URLQueryItem(name: "q", value: text)
        let offsetQueryItem = URLQueryItem(name: "offset", value: "\(offset)")
        let limitQueryItem = URLQueryItem(name: "limit", value: "\(limit)")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlComponents.queryItems = [searchQueryItem, keyQueryItem, offsetQueryItem, limitQueryItem]
        
        request.url = urlComponents.url!
        
        print(request.url!)
        return URLSession.shared.rx
            .decodable(request: request, type: GiphySearchResponse.self)
            .map {
                $0.data
                
            }
    }
}
