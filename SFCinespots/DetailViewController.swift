//
//  DetailViewController.swift
//  SFCinespots
//
//  Created by Mike Manzano on 8/8/16.
//  Copyright © 2016 Broham Inc. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

// MARK: Configuration
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            updateDisplayFromDetailItem()
        }
    }

// MARK: UI Components
    
    @IBOutlet weak var webView: UIWebView!
    
// MARK: Display
    
    func updateDisplayFromDetailItem() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            title = detail.valueForKey("title")!.description
        }
    }

// MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        updateDisplayFromDetailItem()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let detail = detailItem {
            
            let locations = detail.valueForKey("locations")!.description.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let regex = try! NSRegularExpression(pattern: "\\(.+\\)", options: [])
            var hint: String? = nil
            regex.enumerateMatchesInString(locations, options: [], range: NSRange(location: 0, length: locations.characters.count), usingBlock: { (result, _, _) in
                let adjustedRange = NSRange(location: result!.range.location + 1, length: result!.range.length - 2)
                hint = (locations as NSString).substringWithRange(adjustedRange)
            })
            
            let hintString = (hint ?? "").stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())! + (hint != nil ? ",%20" : "")
            let locationsString = (locations.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())! as NSString).stringByReplacingOccurrencesOfString("&", withString: "%26").stringByReplacingOccurrencesOfString("(", withString: ",%20").stringByReplacingOccurrencesOfString(")", withString: "")
            let URLString = "https://maps.google.com/?q=" + locationsString + "&near=" + hintString + "San%20Francisco,%20CA"
            print(URLString)
            if let url = NSURL(string: URLString) {
                webView.loadRequest(NSURLRequest(URL: url))
            }
        }
    }
}

