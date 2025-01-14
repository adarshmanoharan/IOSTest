//
//  NetworkManager.swift
//  IOSTest
//
//  Created by Adarsh Manoharan on 17/04/2 R.
//  Copyright © 2 Adarsh Manoharan. All rights reserved.
//

import Foundation
import Reachability
typealias RequestCompletion = (_ error: APIResultStatus?, _ data: Any?) -> Void
class NetworkManager<T: Decodable>: NSObject {
    var completionBlock: RequestCompletion!
    var requestMethod: HTTPMethod!
    var requestUrl: String!
    var formatterRequired: Bool = false
    // MARK: Setup Root
    func setupRoot() -> URL {
        let finalRequestString = Environment.rootURL + Environment.apiKey + "/" + requestUrl
        return URL(string: finalRequestString)!
    }
    // MARK: Request
    func perform(completion: @escaping RequestCompletion) {
        let url = setupRoot()
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = requestMethod.rawValue
        NetworkReachabilityManager.isReachable { (status) in
            if status {
                //create data task
                let dataTask = URLSession.shared.dataTask(with: request) { data, _, err  in
                    guard err == nil else {
                        completion(.failure, err?.localizedDescription ?? "")
                        print("reqeust error: ", err?.localizedDescription ?? "")
                        return
                    }
                    guard data != nil else {
                        print("Error in getting data")
                        DispatchQueue.main.async {
                            completion(.failure, NSLocalizedString("getingContentError", comment: ""))
                        }
                        return
                    }
                    do {
                        //RESPONSE FORMATTER
                        var responseDataModified = data
                        if self.formatterRequired {
                            let responseStrInISOLatin = String(data: data!,
                                                               encoding: String.Encoding.isoLatin1)
                            guard let modifiedDataInUTF8Format =
                                responseStrInISOLatin?.data(using: String.Encoding.utf8) else {
                                    print("could not convert data to UTF-8 format")
                                    return
                            }
                            responseDataModified = modifiedDataInUTF8Format
                        }
                        let decodedResult = try JSONDecoder().decode(T.self, from: responseDataModified!)
                        print("responseFromServer:", decodedResult)
                        DispatchQueue.main.async {
                            completion(.success, decodedResult)
                        }
                    } catch let error as NSError {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            completion(.failure, error.localizedDescription)
                        }
                    }
                }
                dataTask.resume()
            } else {
                completion(.networkIssue, NSLocalizedString("ReachabilityError", comment: ""))
            }
        }
    }
}

//SERVICE STATUS
enum APIResultStatus {
    case success
    case failure
    case networkIssue
}
//REST Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
