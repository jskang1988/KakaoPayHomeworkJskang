//
//  UnsplashNetworkManager.swift
//  KakaoPayHomeworkJskang
//
//  Created by 강진석 on 2021/02/26.
//

import Foundation

class UnsplashNetworkManager {
    static let shared = UnsplashNetworkManager()
    private init() {}
    
    var timeoutInterval = 1000
    var error: Error?
    private var successCodes: CountableRange<Int> = 200..<299
    private var failureCodes: CountableRange<Int> = 400..<499
    
    private(set) var jsonResponse: Any?
    
    let baseUrl = "https://api.unsplash.com/"
    let searchComponentUrl = "/search/photos"
    let allPhotosComponentUrl = "/photos"
    let photosPerPage = 30
    
    func requestAllPhotos(page:Int, completion: @escaping ([UnsplashPhoto]?) -> Void) {
        self.requestPhotos(page: page) { (photos, totalPages) in
            completion(photos)
        }
    }
    
    func requestSearchPhotos(page:Int, query:String, completion: @escaping ([UnsplashPhoto]?, _ totalPages:Int) -> Void) {
        self.requestPhotos(page: page, query: query) { (photos, totalPages) in
            completion(photos, totalPages)
        }
    }
    
    private func requestPhotos(page:Int, query:String? = nil, completion: @escaping ([UnsplashPhoto]?, _ totalPages:Int) -> Void) {
        guard var request = prepareURLRequest(page: page, query: query) else {
            completion(nil, 0)
            return
        }

        request.allHTTPHeaderFields = prepareHeaders()
        request.httpMethod = "get"

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let _ = error {
                completion(nil, 0)
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if self.successCodes.contains(statusCode) {
                    if let rData = data {
                        do {
                            self.jsonResponse = try JSONSerialization.jsonObject(with: rData, options: JSONSerialization.ReadingOptions.init(rawValue: 0))
                            if let _ = query, query != "" {
                                if let photos = self.photosFromSearchJSONResponse(), let totalPages = self.totalPagesFromSearchJSONResponse() {
                                    completion(photos, totalPages)
                                }
                                else {
                                    completion(nil, 0)
                                }
                            }
                            else {
                                if let photos = self.photosFromAllPhotosJSONResponse() {
                                    completion(photos, Int.max)
                                }
                                else {
                                    completion(nil, 0)
                                }
                            }
                        } catch {
                            completion(nil, 0)
                        }
                    }
                    else {
                        completion(nil, 0)
                    }
                    
                } else if self.failureCodes.contains(statusCode) {
                    if let data = data, let responseBody = try? JSONSerialization.jsonObject(with: data, options: []) {
                        debugPrint(responseBody)
                    }
                    completion(nil, 0)
                } else {
                    completion(nil, 0)
                }
            }
            else {
                completion(nil, 0)
            }
        })
        task.resume()
    }
    
    private func prepareURLRequest(page:Int, query: String? = nil) -> URLRequest? {
        let parameters = self.prepareParameters(page: page, query: query)

        guard let url = prepareURLComponents(query: query)?.url else {
            return nil
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.query = queryParameters(parameters)
        return URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: TimeInterval(timeoutInterval))
        
    }
    
    private func prepareURLComponents(query:String?) -> URLComponents? {
        guard let apiURL = URL(string: self.baseUrl) else {
            return nil
        }

        var urlComponents = URLComponents(url: apiURL, resolvingAgainstBaseURL: true)
        if let _ = query, query != "" {
            urlComponents?.path = self.searchComponentUrl
        }
        else {
            urlComponents?.path = self.allPhotosComponentUrl
        }
        return urlComponents
    }
    
    private func photosFromSearchJSONResponse() -> [UnsplashPhoto]? {
        guard let jsonResponse = jsonResponse as? [String: Any],
            let results = jsonResponse["results"] as? [Any] else {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: results, options: [])
            return try JSONDecoder().decode([UnsplashPhoto].self, from: data)
        } catch {
            self.error = error
        }
        return nil
    }
    
    private func totalPagesFromSearchJSONResponse() -> Int? {
        guard let jsonResponse = jsonResponse as? [String: Any],
            let totalPages = jsonResponse["total_pages"] as? Int else {
            return nil
        }

        return totalPages
    }
    
    private func photosFromAllPhotosJSONResponse() -> [UnsplashPhoto]? {
        guard let jsonResponse = self.jsonResponse else {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonResponse, options: [])
            return try JSONDecoder().decode([UnsplashPhoto].self, from: data)
        } catch {
            self.error = error
        }
        return nil
    }

    
    
    private func queryParameters(_ parameters: [String: Any]?, urlEncoded: Bool = false) -> String {
        var allowedCharacterSet = CharacterSet.alphanumerics
        allowedCharacterSet.insert(charactersIn: ".-_")

        var query = ""
        parameters?.forEach { key, value in
            let encodedValue: String
            if let value = value as? String {
                encodedValue = urlEncoded ? value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? "" : value
            } else {
                encodedValue = "\(value)"
            }
            query = "\(query)\(key)=\(encodedValue)&"
        }
        return query
    }
    
    private func prepareHeaders() -> [String: String]? {
        var headers = [String: String]()
        headers["Authorization"] = "Client-ID gb-8jUGP6kehDo8s_U0rNldfwp4dwX1QS-LcTEFtjAM"
        return headers
    }
    
    private func prepareParameters(page:Int, query:String? = nil) -> [String: Any]? {
        var parameters = [String: Any]()
        parameters["page"] = page
        parameters["per_page"] = self.photosPerPage
        if let _ = query, query != "" {
            parameters["query"] = query
        }

        return parameters
    }
    
}
