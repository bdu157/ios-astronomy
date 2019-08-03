//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoReference = photoReferences[indexPath.item]

        operations[photoReference.id]?.cancel()
        print("cancelling operations")
        
    }
    
    // MARK: - Private
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = photoReferences[indexPath.item]
        
        // TODO: Implement image loading here
        
        let fetchPhotoOperation = FetchPhotoOperation(marsPhotoReference: photoReference)
        
        let cachedOperation = BlockOperation {
            if let data = fetchPhotoOperation.imageData {
                self.cache.cache(value: data, for: photoReference.id)
            }
        }
        
        let checkReuseOperation = BlockOperation {
            if let currentIndexPath = self.collectionView.indexPath(for: cell) {
                if currentIndexPath != indexPath {
                    return
                } else {
                    if let data = fetchPhotoOperation.imageData {
                        let image = UIImage(data: data)
                        cell.imageView.image = image
                    }
                }
            }
        }
        
        cachedOperation.addDependency(fetchPhotoOperation)
        checkReuseOperation.addDependency(fetchPhotoOperation)
        
        photoFetchQueue.addOperation(fetchPhotoOperation)
        photoFetchQueue.addOperation(cachedOperation)
        OperationQueue.main.addOperation(checkReuseOperation)
        
        self.operations[photoReference.id] = fetchPhotoOperation
    
    }
        /* //rewriting this part using Operations
         if let cachedValue = cache.value(for: photoReference.id) {
         let image = UIImage(data: cachedValue)
         cell.imageView.image = image
         } else {
        let request = URLRequest(url: photoReference.imageURL.usingHTTPS!)
         
             URLSession.shared.dataTask(with: request) { (data, _, error) in
                if let error = error {
                    NSLog("there is an error in getting an image: \(error)")
                    return
                }
         
                guard let data = data else {
                    NSLog("there is an error in getting a data")
                    return
                }
                guard let image = UIImage(data: data) else {
                    return
                }
                self.cache.cache(value: data, for: photoReference.id)
                
                DispatchQueue.main.async {
                    cell.imageView.image = image
                }
            }.resume()
         }
     
 */
    // Properties
    
    var cache = Cache<Int, Data>()
    private let client = MarsRoverClient()
    private let photoFetchQueue = OperationQueue()
    private var operations = [Int : Operation]()
    
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[10]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
}
