//
//  AppVersionView.swift
//  Dial
//
//  Created by KrLite on 2024/3/24.
//

import SwiftUI

struct AppVersionView: View {
    var body: some View {
        HStack {
            Text("Version \(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
            
            Button(action: {
                copyToClipboard("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
            }, label: {
                Image(systemSymbol: .clipboardFill)
            })
            .buttonStyle(.plain)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    AppVersionView()
}
