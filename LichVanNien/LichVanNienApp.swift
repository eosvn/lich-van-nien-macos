//
//  LichVanNienApp.swift
//  LichVanNien
//
//  Created by Be Tai on 15/9/25.
//

import SwiftUI

@main
struct LichVanNienApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().frame(width: 800, height: 800) // Kích thước cố định
        }
        .windowResizability(.contentSize)
    }
}
