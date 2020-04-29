//
//  Logger.swift
//  LivenessEngineIosExample
//
//  Created by VisionLabs on 07.09.17.
//  Copyright © 2017 VisionLabs. All rights reserved.
//

import Foundation

class Logger {
    
    static var verbose : Int = 5
    
    class func setVerbose(value:Int) {
        verbose = value
    }
    
	class func error(_ message: String,
	               function: String = #function,
	               file: String = #file,
	               line: Int = #line) {
		
		let url = NSURL(fileURLWithPath: file)
		
		print("!!! Error \"\(message)\" \n ↳(File: \(url.lastPathComponent ?? "?"), Function: \(function), Line: \(line)) \n")
	}
	class func log(_ message: String,
	               function: String = #function,
	               file: String = #file,
	               line: Int = #line) {
		
		let url = NSURL(fileURLWithPath: file)
		
        if (verbose > 2) {
            print("LOG: \"\(message)\" \n ↳ lvl 3 (File: \(url.lastPathComponent ?? "?"), Function: \(function), Line: \(line)) \n")
        }
	}
    class func log_LowPriority(_ message: String,
                   function: String = #function,
                   file: String = #file,
                   line: Int = #line) {
        
        let url = NSURL(fileURLWithPath: file)
        
        if (verbose > 4) {
            print("LOG: \"\(message)\" \n ↳ lvl 5 (File: \(url.lastPathComponent ?? "?"), Function: \(function), Line: \(line)) \n")
        }
    }
    
    class func logHighPriority(_ message: String,
                   function: String = #function,
                   file: String = #file,
                   line: Int = #line) {
        
        let url = NSURL(fileURLWithPath: file)
        
        if (verbose > 0) {
            print("LOG: \"\(message)\" \n ↳ lvl 1 (File: \(url.lastPathComponent ?? "?"), Function: \(function), Line: \(line)) \n")
        }
    }
    
}
