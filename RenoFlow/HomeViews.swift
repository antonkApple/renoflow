import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @State private var showingAddProject = false
    @State private var newProjectName = ""

    var body: some View {
        List {
            Section {
                Picker("Region", selection: $store.selectedRegion) {
                    ForEach(Region.allCases) { region in
                        Text(region.rawValue).tag(region)
                    }
                }
            }
            Section("Projects") {
                ForEach(store.projects) { project in
                    NavigationLink(value: project.id) {
                        ProjectCard(project: project)
                    }
                }
            }
        }
        .navigationTitle("RenoFlow")
        .toolbar {
            NavigationLink {
                StoreManagementView()
            } label: {
                Label("Stores", systemImage: "storefront")
            }
            Button {
                showingAddProject = true
            } label: {
                Label("Add Project", systemImage: "plus")
            }
        }
        .navigationDestination(for: UUID.self) { projectID in
            if let project = store.projects.first(where: { $0.id == projectID }) {
                ProjectView(project: project)
            }
        }
        .alert("Add Project", isPresented: $showingAddProject) {
            TextField("Project name", text: $newProjectName)
            Button("Cancel", role: .cancel) { newProjectName = "" }
            Button("Save") {
                let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addProject(named: name.isEmpty ? "New Renovation" : name)
                newProjectName = ""
            }
        }
    }
}

struct ProjectCard: View {
    let project: ProjectEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(project.name).font(.headline)
                Spacer()
                Text(project.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold))
            }
            ProgressView(value: project.progress)
            HStack {
                Label("\(project.totalItems) items", systemImage: "list.bullet")
                Spacer()
                Text("Spent \(project.totalSpent, format: .currency(code: "USD"))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
