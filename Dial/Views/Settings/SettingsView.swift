//
//  SettingsView.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import SFSafeSymbols

struct SettingsView: View {
    enum Tabs: Hashable {
        case general
        case controllers
        case about
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemSymbol: .gearshape)
                }
                .tag(Tabs.general)
            
            ControllersSettingsView()
                .tabItem {
                    Label("Controllers", systemSymbol: .sliderVertical3)
                }
                .tag(Tabs.controllers)
        }
        .frame(minWidth: 580, minHeight: 460)
    }
}
