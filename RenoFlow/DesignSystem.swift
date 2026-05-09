import SwiftUI

enum RenoTheme {
    enum ColorToken {
        static let background = Color(red: 0.961, green: 0.957, blue: 0.945)
        static let surface = Color.white
        static let secondarySurface = Color(red: 0.925, green: 0.914, blue: 0.890)
        static let elevatedSurface = Color(red: 0.985, green: 0.982, blue: 0.973)
        static let text = Color(red: 0.105, green: 0.098, blue: 0.086)
        static let secondaryText = Color(red: 0.485, green: 0.462, blue: 0.425)
        static let tertiaryText = Color(red: 0.635, green: 0.612, blue: 0.570)
        static let hairline = Color(red: 0.850, green: 0.832, blue: 0.790)
        static let accent = Color(red: 0.788, green: 0.471, blue: 0.196)
        static let accentSoft = Color(red: 0.965, green: 0.875, blue: 0.780)
        static let accentMuted = Color(red: 0.722, green: 0.416, blue: 0.184)
        static let greenSoft = Color(red: 0.820, green: 0.890, blue: 0.810)
        static let greenText = Color(red: 0.270, green: 0.430, blue: 0.300)
        static let blueGraySoft = Color(red: 0.815, green: 0.855, blue: 0.875)
        static let blueGrayText = Color(red: 0.260, green: 0.390, blue: 0.455)
        static let amberSoft = Color(red: 0.945, green: 0.840, blue: 0.670)
        static let amberText = Color(red: 0.570, green: 0.380, blue: 0.130)
        static let warmGraySoft = Color(red: 0.900, green: 0.880, blue: 0.840)
        static let warmGrayText = Color(red: 0.390, green: 0.365, blue: 0.325)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 36
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 28
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.055)
        static let elevatedColor = Color.black.opacity(0.090)
    }
}

extension View {
    func renoScreenBackground() -> some View {
        background(RenoTheme.ColorToken.background.ignoresSafeArea())
    }

    func renoCardStyle(cornerRadius: CGFloat = RenoTheme.Radius.lg) -> some View {
        background(RenoTheme.ColorToken.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: RenoTheme.Shadow.cardColor, radius: 18, x: 0, y: 10)
    }
}

struct RenoPage<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                    Text(title)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    }
                }
                .padding(.top, RenoTheme.Spacing.md)
                content
            }
            .padding(.horizontal, RenoTheme.Spacing.lg)
            .padding(.bottom, RenoTheme.Spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .renoScreenBackground()
    }
}

struct RenoSection<Content: View>: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                Spacer()
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.accent)
                }
            }
            content
        }
    }
}

struct RenoCard<Content: View>: View {
    var padding: CGFloat = RenoTheme.Spacing.lg
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
            content
        }
        .padding(padding)
        .renoCardStyle()
    }
}

struct RenoPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, RenoTheme.Spacing.lg)
            .padding(.vertical, RenoTheme.Spacing.md)
            .background(RenoTheme.ColorToken.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct RenoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(RenoTheme.ColorToken.text)
            .padding(.horizontal, RenoTheme.Spacing.md)
            .padding(.vertical, RenoTheme.Spacing.sm)
            .background(RenoTheme.ColorToken.secondarySurface.opacity(configuration.isPressed ? 0.70 : 1), in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct RenoIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(RenoTheme.ColorToken.text)
            .frame(width: 44, height: 44)
            .background(RenoTheme.ColorToken.surface.opacity(configuration.isPressed ? 0.75 : 1), in: Circle())
            .shadow(color: RenoTheme.Shadow.cardColor, radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct RenoSegmentedPicker<Selection: Hashable, Content: View>: View {
    @Binding var selection: Selection
    @ViewBuilder var content: Content

    var body: some View {
        Picker("", selection: $selection) {
            content
        }
        .pickerStyle(.segmented)
        .tint(RenoTheme.ColorToken.accent)
    }
}

struct RenoProgressBar: View {
    let value: Double
    var height: CGFloat = 8

    private var clampedValue: Double { min(max(value, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(RenoTheme.ColorToken.secondarySurface)
                Capsule()
                    .fill(RenoTheme.ColorToken.accent)
                    .frame(width: max(proxy.size.width * clampedValue, clampedValue > 0 ? height : 0))
            }
        }
        .frame(height: height)
    }
}

struct RenoStatusChip: View {
    let status: ItemStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.backgroundColor, in: Capsule())
    }
}

struct RenoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(RenoTheme.ColorToken.accent)
                    .frame(width: 50, height: 50)
                    .background(RenoTheme.ColorToken.accentSoft, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
                VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let buttonTitle, let action {
                    Button(action: action) {
                        Label(buttonTitle, systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RenoPrimaryButtonStyle())
                }
            }
        }
    }
}

extension ItemStatus {
    var backgroundColor: Color {
        switch self {
        case .planned: RenoTheme.ColorToken.warmGraySoft
        case .ordered: RenoTheme.ColorToken.amberSoft
        case .delivered: RenoTheme.ColorToken.blueGraySoft
        case .installed: RenoTheme.ColorToken.greenSoft
        }
    }

    var textColor: Color {
        switch self {
        case .planned: RenoTheme.ColorToken.warmGrayText
        case .ordered: RenoTheme.ColorToken.amberText
        case .delivered: RenoTheme.ColorToken.blueGrayText
        case .installed: RenoTheme.ColorToken.greenText
        }
    }
}
