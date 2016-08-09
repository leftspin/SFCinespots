//
//  Utility.swift
//  SFCinespots
//
//  Created by Mike Manzano on 8/8/16.
//  Copyright © 2016 Broham Inc. All rights reserved.
//

import Foundation

func async(block: () -> Void) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func background(block: () -> Void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block)
}

func delay(seconds: time_t, block: () -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), block)
}