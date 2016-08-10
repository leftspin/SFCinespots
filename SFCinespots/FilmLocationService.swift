//
//  FilmLocationService.swift
//  SFCinespots
//
//  Created by Mike Manzano on 8/8/16.
//  Copyright © 2016 Broham Inc. All rights reserved.
//

import UIKit
import CoreData

class FilmLocationService {
    
// MARK: Instance
    
    /// The shared instance
    static let shared = FilmLocationService()
    
// MARK: Configuration
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
// MARK: State
    
    var isCurrentlyLoading = false
    
// MARK: Constants
    
    enum Notifications: String {
        case FailedToFetchNotification = "FailedToFetchNotification"
        case FailedToParseNotification = "FailedToParseNotification"
    }
    
// MARK: FilmLocationService
    
    /// Load the film data from the service and call `mapJSON`
    func loadFilmData() {

        func postErrorNotification(message: String) {
            async {
                print("\(message)")
                let notification = NSNotification(name: Notifications.FailedToFetchNotification.rawValue, object: self, userInfo: [NSLocalizedDescriptionKey:message])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
        
        if isCurrentlyLoading {
            return
        }

        guard let url = NSURL(string: "https://data.sfgov.org/resource/wwmu-gmzc.json?$select=title,release_year,locations") else {
            postErrorNotification("Could not create URL")
            return
        }

        isCurrentlyLoading = true
        
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: {
            (possibleData, possibleResponse, possibleError) in
            
            self.isCurrentlyLoading = false
            
            if let error = possibleError {
                postErrorNotification("Error fetching data: \(error)")
            } else {
                guard let data = possibleData else {
                    postErrorNotification("No data was fetched")
                    return
                }
                
                background {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        self.mapJSON(json)
                    }
                    catch let error {
                        postErrorNotification("Could not parse JSON: \(error)")
                    }
                } // background
            } // if error
        }).resume() // dataTaskWithURL
    }
    
    /// Map `json` into core data
    /// - parameter json: The JSON to map into core data.
    func mapJSON(json: AnyObject) {
        
        func postErrorNotification(message: String) {
            async {
                print("\(message)")
                let notification = NSNotification(name: Notifications.FailedToParseNotification.rawValue, object: self, userInfo: [NSLocalizedDescriptionKey:message])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
        
        guard let context = managedObjectContext else {
            postErrorNotification("Unconfigured managed object context.")
            return
        }

        guard let jsonDict = json as? [[String: String]] else {
            postErrorNotification("Unexpected root object")
            return
        }

        // back to the main queue so we can access `managedObjectContext`
        async {
            // and right back into a different thread to load up core data…
            let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            privateMOC.parentContext = context
            privateMOC.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            privateMOC.performBlock {
                
                guard let entity = NSEntityDescription.entityForName("FilmLocation", inManagedObjectContext: privateMOC) else {
                    postErrorNotification("Could not get managed object model entity")
                    return
                }
        
                // Create the managed objects
                jsonDict.forEach {
                    filmLocationDict in
                    
                    if  let title = filmLocationDict["title"],
                        let locations = filmLocationDict["locations"] {
                        
                        // Is it in there?
                        let request = NSFetchRequest(entityName: entity.name!)
                        request.predicate = NSPredicate(format: "title == %@ && locations == %@", title, locations)
                        let results = try! privateMOC.executeFetchRequest(request) as! [NSManagedObject]
                        if results.count == 0 {
                            let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: privateMOC)
                            newManagedObject.setValue(title, forKey: "title")
                            newManagedObject.setValue(locations, forKey: "locations")
                            newManagedObject.setValue(filmLocationDict["release_year"] ?? NSNull(), forKey: "release_year")
                        } else {
                            results.forEach {
                                result in
                                result.setValue(title, forKey: "title")
                                result.setValue(locations, forKey: "locations")
                                result.setValue(filmLocationDict["release_year"] ?? NSNull(), forKey: "release_year")
                            }
                        } // if results
                    } // if let
                } // each entry
        
                // Save the context
                do {
                    print("Saving private MOC")
                    try privateMOC.save()

                    context.performBlock {
                        // Save the parent context
                        do {
                            print("Saving global MOC")
                            try context.save()
                        } catch let error {
                            async { print("An error occurred saving the MOC: \(error)") }
                        }
                    }
                    
                } catch let error {
                    async { print("An error occurred saving the private MOC: \(error)") }
                }
                
            }
        } // async
    }
}
