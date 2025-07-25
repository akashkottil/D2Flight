//
//  MasonryGrid.swift
//  D2Flight
//
//  Created by Akash Kottil on 25/07/25.
//

import SwiftUI

struct MasonryGrid<T: Identifiable, Content: View>: View {
    let data: [T]
    let columns: Int
    let content: (T) -> Content

    init(data: [T], columns: Int, @ViewBuilder content: @escaping (T) -> Content) {
        self.data = data
        self.columns = columns
        self.content = content
    }

    private func splitDataIntoColumns() -> [[T]] {
        var columnsArray = Array(repeating: [T](), count: columns)
        for (index, item) in data.enumerated() {
            columnsArray[index % columns].append(item)
        }
        return columnsArray
    }

    var body: some View {
        let columnsData = splitDataIntoColumns()

        HStack(alignment: .top, spacing: 8) {
            ForEach(0..<columnsData.count, id: \.self) { columnIndex in
                VStack(spacing: 8) {
                    ForEach(columnsData[columnIndex]) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
