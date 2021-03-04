//
//  GiphyService.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import Foundation
import RxSwift

protocol GiphyServiceProtocol {
    func search(text: String, offset: Int, limit: Int) -> Observable<[GiphyItem]>
    func downloadGif(url: URL) -> Observable<Data>
}

class GiphyService: GiphyServiceProtocol {
    
    // MARK: Vars
    
    private let apiKey = "X09nb1IgWr4u7dxoMJbZ8iQs3ClrlAM0"
    
    // MARK: Methods
    
    func search(text: String, offset: Int, limit: Int) -> Observable<[GiphyItem]> {
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
            .map {$0.data.elements}
    }
    
    func downloadGif(url: URL) -> Observable<Data> {
        return URLSession.shared.rx.data(request: URLRequest(url: url))
    }
}
