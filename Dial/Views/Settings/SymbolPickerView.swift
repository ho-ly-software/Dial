//
//  SymbolPickerView.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import SFSafeSymbols

struct SymbolPickerView: View {
    @Binding var selectedSymbol: SFSymbol
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    private var symbols: [SFSymbol] {
        let all = SFSymbol.__circleFillableSymbols
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return all
        }
        return all.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText.trimmingCharacters(in: .whitespaces)) }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 48), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Symbol")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding([.top, .horizontal])
            
            TextField("Search Symbols", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            Image(systemSymbol: symbol)
                                .font(.system(size: 20))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedSymbol == symbol ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(selectedSymbol == symbol ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selectedSymbol == symbol ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(symbol.rawValue)
                    }
                }
                .padding()
            }
            .frame(width: 340, height: 280)
        }
    }
}
