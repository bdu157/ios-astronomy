//
//  FetchPhotoOperation.swift
//  Astronomy
//
//  Created by Dongwoo Pae on 8/2/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class FetchPhotoOperation: ConcurrentOperation {
    
    var imageData: Data?
    var dataTask: URLSessionDataTask?
    
    override func start() {
        state = .isExecuting
        
        let request = URLRequest(url: self.imageURL.usingHTTPS!)
    
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if self.isCancelled {return}
            
            if let error = error {
                NSLog("there is an error in getting the data: \(error)")
                return
            }
            
            guard let data = data else {
                NSLog("there is an error in getting data")
                return
            }
            
            //defer?? for state of .isFinished(?) - defer is making sure this gets called at the end of this completion closure.
            defer {self.state = .isFinished}
            self.imageData = data
        }
        
        //store the task itself in a private property(?) -> assign task to whole urlSession and get it assigned to self.dataTask
        task.resume()
        self.dataTask = task
    }
    
    override func cancel() {
        //cancel datatask(?)
        dataTask?.cancel()
    }
    
    let id: Int
    let sol: Int
    let camera: Camera
    let earthDate: Date
    let imageURL: URL

    init(marsPhotoReference: MarsPhotoReference) {
        self.id = marsPhotoReference.id
        self.sol = marsPhotoReference.sol
        self.camera = marsPhotoReference.camera
        self.earthDate = marsPhotoReference.earthDate
        self.imageURL = marsPhotoReference.imageURL
    }
}
