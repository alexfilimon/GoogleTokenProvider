//
//  Base.swift
//  
//
//  Created by Alexander Filimonov on 01/03/2020.
//

import Foundation
#if os(OSX)
  import Cocoa
#endif

/// Method for opening URL in browser or printing it in CLI
internal func openURL(_ url: URL) {
  #if os(OSX)
    if !NSWorkspace.shared.open(url) {
      print("default browser could not be opened")
    }
  #else // Linux
    print("To continue, please open this URL in your browser: (\(String(describing:url)))")
  #endif
}
