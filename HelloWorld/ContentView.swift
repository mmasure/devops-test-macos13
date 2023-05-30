//
//  ContentView.swift
//  HelloWorld
//
//  Created by Maxime Marinel on 16/05/2023.
//

import SwiftUI

extension Bundle {
    public var appName: String           { getInfo("CFBundleName")  }
    public var displayName: String       { getInfo("CFBundleDisplayName")}
    public var language: String          { getInfo("CFBundleDevelopmentRegion")}
    public var identifier: String        { getInfo("CFBundleIdentifier")}
    public var copyright: String         { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String          { getInfo("CFBundleVersion") }
    public var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Text("Ver: \(Bundle.main.appVersionLong) (\(Bundle.main.appBuild)) ")
        
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
