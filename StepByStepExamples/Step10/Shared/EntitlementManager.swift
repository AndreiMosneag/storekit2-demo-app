//
//  EntitlementManager.swift
//  Step10
//
//  Created by Mosenag Andrei on 11/07/23.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.your.app")!

    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false
}
