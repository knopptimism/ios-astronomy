//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var photoReferences = [MarsPhotoReference]() {
           didSet {
               DispatchQueue.main.async { self.collectionView?.reloadData() }
           }
       }
    let cache = Cache <Int, Data> ()
    let photoFetchQueue = OperationQueue()
    private let client = MarsRoverClient()
    private var ops = [Int: Operation]()
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[105]
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
       
    @IBOutlet var collectionView: UICollectionView!
       
    
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
    

    
    
    // MARK: - Properties
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = photoReferences[indexPath.item]
        
        // Abstract of the photo
        if let photo = cache.value(for: photoReference.id) {
            let image = UIImage(data: photo)
            cell.imageView.image = image
        }
        // Pull the data from the net
        else {
            let photoFetchOp = FetchPhotoOperation(reference: photoReference)
            let cacheOperation = BlockOperation {
                if let data = photoFetchOp.data {
                    self.cache.cache(value: data, for: photoReference.id)
                    
                }
            }
            let setImageQueue = BlockOperation {
                DispatchQueue.main.async {
                    if let data = photoFetchOp.data {
                        cell.imageView.image = UIImage(data: data)
                    }
                }
            }
            cacheOperation.addDependency(photoFetchOp)
            cacheOperation.addDependency(photoFetchOp)
            
            photoFetchQueue.addOperations ([
            photoFetchOp, cacheOperation], waitUntilFinished: false)
            
            OperationQueue.main.addOperation(setImageQueue)
            ops[photoReference.id] = photoFetchOp
        
        // TODO: Implement image loading here
    }
}
   
    
    
   
    
    
    
    
    
    
    
   
}

