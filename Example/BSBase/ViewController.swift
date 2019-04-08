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

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        urlEncoding()
//        jsonEncoding()
        
        dataUpload()
        
        
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
    
}
