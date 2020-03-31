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

private func shell(_ args: String...) -> Int32 {
  let task = Process()
  if #available(macOS 10.13, *) {
    task.executableURL = URL(string: "/usr/bin/env")
  } else {
    task.launchPath = "/usr/bin/env"
  }
  task.arguments = args
  if #available(macOS 10.13, *) {
    do {
      try task.run()
    } catch {
      return -1
    }
  } else {
    task.launch()
  }
  task.waitUntilExit()
  return task.terminationStatus
}

/// Method for opening URL in browser or printing it in CLI
internal func openURL(_ url: URL) {
  #if os(OSX)
    if !NSWorkspace.shared.open(url) {
      print("default browser could not be opened")
    }
  #else // Linux, tested on Ubuntu
    let status = shell("xdg-open", String(describing:url))
    if status != 0 {
        print("To continue, please open this URL in your browser: (\(String(describing:url)))")
    }
  #endif
}
