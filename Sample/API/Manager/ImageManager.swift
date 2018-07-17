//
//  ImageManager.swift
//  Sample
//
//  Created by Théophane Rupin on 4/8/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import UIKit
import WeaverDI

public enum ImageManagerError: Error {
    case oops
}

public protocol ImageManaging {
    
    func getImage(with path: String, completion: @escaping (Result<UIImage, ImageManagerError>) -> Void)
}

public final class ImageManager: ImageManaging {
    
    private let dependencies: ImageManagerDependencyResolver
    
    // weaver: logger = Logger
    
    // weaver: urlSession = URLSession
    // weaver: urlSession.scope = .container
    
    // weaver: movieAPI <- APIProtocol
    
    var imagesByUrl = [String: UIImage]()
    
    init(injecting dependencies: ImageManagerDependencyResolver) {
        self.dependencies = dependencies
    }
    
    public func getImage(with path: String, completion: @escaping (Result<UIImage, ImageManagerError>) -> Void) {
        
        let request = APIRequest<Data>(method: .get, host: MovieAPI.Constants.imageAPIHost, path: path)
        
        dependencies.movieAPI.send(request: request) { result in
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completion(.failure(.oops))
                    return
                }
                completion(.success(image))
                
            case .failure(let error):
                self.dependencies.logger.log(.error, "\(error)")
                completion(.failure(.oops))
            }
        }
    }
}
