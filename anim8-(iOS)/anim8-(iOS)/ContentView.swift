//
//  ContentView.swift
//  anim8-(iOS)
//
//  Created by Gunjan Haider on 03/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GalleryDetailView(items: GalleryItem.sampleItems, startIndex: 5)
    }
}

#Preview {
    ContentView()
}
