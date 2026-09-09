import SwiftUI

struct BreedsListView: View {
    @State private var viewModel = BreedsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Could not load breeds",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.breeds.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    ForEach(viewModel.breeds) { breed in
                        BreedRow(breed: breed)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Breeds")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search breeds"
            )
            .overlay {
                if viewModel.isLoading && viewModel.breeds.isEmpty {
                    ProgressView()
                }
            }
        }
        .task { viewModel.onAppear() }
    }
}

struct BreedRow: View {
    let breed: Breed

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(breed.name)
                .font(.body)
            if let origin = breed.origin, !origin.isEmpty {
                Text(origin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BreedsListView()
}
