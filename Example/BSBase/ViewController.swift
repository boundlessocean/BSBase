//
//  ViewController.swift
//  BSBase
//
//  Created by fuhaiyang on 04/08/2019.
//  Copyright (c) 2019 fuhaiyang. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
//    路由器与请求适配器有什么逻辑？
//    简单的静态数据（如路径，HTTP方法和公共标头）属于Router。动态数据，例如Authorization其值可以基于认证系统而改变的标题属于a RequestAdapter。
    

    open var mysessionManager :SessionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        urlEncoding()
//        jsonEncoding()
//        dataUpload()
//        sessionManagertest()
//        requestConfig()
//        myRouter()
        myAdapter()
    }
}


extension ViewController {
    
    @objc public func requset() {
        Alamofire.request("https://httpbin.org/get").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }
    
    
    @objc public func urlEncoding() {
//        let parameters: Parameters = ["foo": "bar"]
//
//        // All three of these calls are equivalent
//        Alamofire.request("https://httpbin.org/get", parameters: parameters) // encoding defaults to `URLEncoding.default`
//        Alamofire.request("https://httpbin.org/get", parameters: parameters, encoding: URLEncoding.default)
//        Alamofire.request("https://httpbin.org/get", parameters: parameters, encoding: URLEncoding(destination: .httpBody))
        
        let urlEncodeParameters: Parameters = [
            "foo": "bar",
            "baz": ["a", false],
            "qux": [
                "x": 1,
                "y": 2,
                "z": 3
            ]
        ]
        
        // All three of these calls are equivalent
        //        Alamofire.request("https://httpbin.org/post", method: .post, parameters: parameters)
        //        Alamofire.request("https://httpbin.org/post", method: .post, parameters: parameters, encoding: URLEncoding.default)
        let encoding = URLEncoding.init(destination: .methodDependent, arrayEncoding: .noBrackets, boolEncoding: .literal)
        
        Alamofire.request("https://httpbin.org/post", method: .post, parameters: urlEncodeParameters, encoding: encoding)
        
    }
    
    
    @objc public func jsonEncoding() {
        let parameters: Parameters = [
            "foo": "bar",
            "baz": ["a", false],
            "qux": [
                "x": 1,
                "y": 2,
                "z": 3
            ]
        ]
        
        Alamofire.request("https://httpbin.org/post", method: .post, parameters: parameters, encoding: JSONEncoding.default)
    }
    
    @objc public func dataUpload() {
        let data = UIImagePNGRepresentation(UIImage(named: "1")!)!
        
        let parameters: [String: String] = ["foo": "bar"]
        Alamofire.upload(
            multipartFormData: { MultipartFormData in
                MultipartFormData.append(data, withName: "unicorn")
                // 其余参数绑定
                for (key, value) in parameters {
                    let date = value.data(using: String.Encoding.utf8)!
                    MultipartFormData.append(date, withName: key)
                }
            },
            to: "https://httpbin.org/post",
            encodingCompletion: { encodingResult in
                            switch encodingResult {
                            case .success(let upload, _, _):
                                upload.responseJSON { response in
                                    debugPrint(response)
                                }
                            case .failure(let encodingError):
                                print(encodingError)
                            }
        })
    }
    
    
    
    
    @objc public func sessionManagertest() {
        var defaultHeaders = SessionManager.defaultHTTPHeaders
        defaultHeaders["DNT"] = "1 (Do Not Track Enabled)"
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders
        
        mysessionManager = SessionManager(configuration: configuration)
        mysessionManager!.request("https://httpbin.org/get").responseJSON { Response in
            print(Response)
        }
    }
    
    
    @objc public func requestConfig(){
        request(BSHttpURL("dad")).response { (DataResponse) in
            print(DataResponse)
        }
    }
    
    @objc public func myRouter(){
        request(Router.search(query: "foo bar", page: 1))
    }
    
    
    @objc public func myAdapter(){
//        mysessionManager = SessionManager.default;
//        mysessionManager?.adapter = AccessTokenAdapter(accessToken: "1234")
//        mysessionManager?.request("https://httpbin.org/get")
        Alamofire.request("https://example.com/users/mattt").responseJSON { (response: DataResponse<Any>) in
            let userResponse = response.map { json in
                // We assume an existing User(json: Any) initializer
                return User(json: json)
            }
            
            // Process userResponse, of type DataResponse<User>:
            if let user = userResponse.value {
                print("User: { username: \(user.username), name: \(user.name) }")
            }
        }
    }
    
}


class BSHttpURL: NSObject,URLConvertible {
    static let baseURLString = "https://example.com"
    var urlname:String?
    
    init(_ name:String) {
        urlname = name
    }
    func asURL() throws -> URL {
        let urlString = BSHttpURL.baseURLString + "/users/\(urlname!)"
        return try urlString.asURL()
    }
}

enum Router: URLRequestConvertible {
    case search(query: String, page: Int)
    
    static let baseURLString = "https://example.com"
    static let perPage = 50
    
    // MARK: URLRequestConvertible
    
    func asURLRequest() throws -> URLRequest {
        let result: (path: String, parameters: Parameters) = {
            switch self {
            case let .search(query, page) where page > 0:
                return ("/search", ["q": query, "offset": Router.perPage * page])
            case let .search(query, _):
                return ("/search", ["q": query])
            }
        }()
        
        let url = try Router.baseURLString.asURL()
        let urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
        
        return try URLEncoding.default.encode(urlRequest, with: result.parameters)
    }
}


class AccessTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix("https://httpbin.org") {
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        
        return urlRequest
    }
}
