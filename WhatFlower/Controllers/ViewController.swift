//
//  ViewController.swift
//  WhatFlower
//
//  Created by Mathieu Delehaye on 6/17/20.
//  Copyright © 2020 Mathieu Delehaye. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageLabel: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    let imagePicker = UIImagePickerController()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage =  CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage into CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func  detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            
            print(results)
            
            if let firstResult = results.first {
                let foundResult = firstResult.identifier
                self.navigationItem.title = foundResult.capitalized
                self.requestInfo(flowerName: foundResult)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the Wikipedia info.")
                
                print(response)
                
                let flowerJSON = JSON(response.result.value!)
                   
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
               
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
            
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                print(flowerImageURL)
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.imageLabel.text = flowerDescription
                
            }
        }
        
   }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

