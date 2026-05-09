import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @State private var showingAddProject = false
    @State private var newProjectName = ""

    var body: some View {
        RenoPage(title: "RenoFlo", subtitle: "Collect products, plan room by room, and track what is still left to buy.") {
            regionCard
            RenoSection(title: "Projects") {
                if store.projects.isEmpty {
                    RenoEmptyState(
                        icon: "house",
                        title: "Start a renovation collection",
                        message: "Create a project, then organize products by room and purchase progress.",
                        buttonTitle: "Add Project"
                    ) {
                        showingAddProject = true
                    }
                } else {
                    VStack(spacing: RenoTheme.Spacing.md) {
                        ForEach(store.projects) { project in
                            NavigationLink(value: project.id) {
                                ProjectCard(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    StoreManagementView()
                } label: {
                    Image(systemName: "storefront")
                }
                .buttonStyle(RenoIconButtonStyle())

                Button {
                    showingAddProject = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(RenoIconButtonStyle())
            }
        }
        .navigationDestination(for: UUID.self) { projectID in
            ProjectView(projectID: projectID)
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
        .tint(RenoTheme.ColorToken.accent)
    }

    private var regionCard: some View {
        RenoCard {
            HStack(spacing: RenoTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                    Text("Region")
                        .font(.subheadline)
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    Text(store.selectedRegion.rawValue)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                }
                Spacer()
                Picker("Region", selection: $store.selectedRegion) {
                    ForEach(Region.allCases) { region in
                        Text(region.rawValue).tag(region)
                    }
                }
                .pickerStyle(.menu)
                .tint(RenoTheme.ColorToken.accent)
            }
        }
    }
}

struct ProjectCard: View {
    let project: ProjectEntity

    var body: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
                HStack(alignment: .top, spacing: RenoTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                        Text(project.name)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(RenoTheme.ColorToken.text)
                            .lineLimit(2)
                        Text("\(project.rooms.count) rooms · \(project.totalItems) products")
                            .font(.subheadline)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    }
                    Spacer()
                    Text(project.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                }

                RenoProgressBar(value: project.progress)

                HStack(spacing: RenoTheme.Spacing.md) {
                    ProjectMiniMetric(title: "Spent", value: project.totalSpent.formatted(.currency(code: "USD")))
                    ProjectMiniMetric(title: "Budget", value: project.totalBudget.formatted(.currency(code: "USD")))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
                }
            }
        }
    }
}

struct ProjectMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
