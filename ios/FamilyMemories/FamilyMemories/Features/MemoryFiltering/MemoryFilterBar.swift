import SwiftUI

struct MemoryFilterBar: View {
    @Binding var filter: AlbumFilterState

    let years: [Int]
    let people: [String]
    let onReset: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("album.filter.allYears") {
                        filter.year = nil
                    }

                    ForEach(years, id: \.self) { year in
                        Button {
                            filter.year = year
                        } label: {
                            Text(verbatim: String(year))
                        }
                    }
                } label: {
                    Label {
                        if let year = filter.year {
                            Text(verbatim: String(year))
                        } else {
                            Text("album.filter.allYears")
                        }
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .buttonStyle(.bordered)

                Menu {
                    Button("album.filter.allPeople") {
                        filter.person = nil
                    }

                    ForEach(people, id: \.self) { person in
                        Button {
                            filter.person = person
                        } label: {
                            Text(verbatim: person)
                        }
                    }
                } label: {
                    Label {
                        if let person = filter.person {
                            Text(verbatim: person)
                        } else {
                            Text("album.filter.allPeople")
                        }
                    } icon: {
                        Image(systemName: "person")
                    }
                }
                .buttonStyle(.bordered)

                if filter.isActive {
                    Button("common.reset") {
                        onReset()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
