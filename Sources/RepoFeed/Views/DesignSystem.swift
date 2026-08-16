import SwiftUI

enum RepoFeedTheme {
    static let background = Color(hex: 0x18191A)
    static let sidebar = Color(hex: 0x242526)
    static let card = Color(hex: 0x242526)
    static let cardElevated = Color(hex: 0x2B2D31)
    static let border = Color(hex: 0x3E4042)
    static let primary = Color(hex: 0x2D88FF)
    static let secondary = Color(hex: 0x45BD62)
    static let muted = Color(hex: 0xB0B3B8)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct CardBackground: ViewModifier {
    var elevated = false

    func body(content: Content) -> some View {
        content
            .background(elevated ? RepoFeedTheme.cardElevated : RepoFeedTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(RepoFeedTheme.border, lineWidth: 1)
            }
    }
}

extension View {
    func repoCard(elevated: Bool = false) -> some View {
        modifier(CardBackground(elevated: elevated))
    }
}

struct TopicPill: View {
    let text: String
    var tint = RepoFeedTheme.secondary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.11), in: Capsule())
    }
}

struct RepoMark: View {
    let seed: String
    var size: CGFloat = 42

    private var colors: [Color] {
        let palettes: [[Color]] = [
            [RepoFeedTheme.primary, Color(hex: 0x178D79)],
            [RepoFeedTheme.secondary, Color(hex: 0x4E5CB8)],
            [Color(hex: 0xFFB86B), Color(hex: 0xC45852)],
            [Color(hex: 0xE89CFF), Color(hex: 0x7654C9)]
        ]
        return palettes[abs(seed.hashValue) % palettes.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.72))
        }
        .frame(width: size, height: size)
    }
}

struct SectionHeading: View {
    let eyebrow: String
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(RepoFeedTheme.primary)
                Text(title)
                    .font(.title2.weight(.bold))
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
            }
        }
    }
}

func compactCount(_ count: Int) -> String {
    switch count {
    case 1_000_000...: String(format: "%.1fM", Double(count) / 1_000_000)
    case 1_000...: String(format: "%.1fk", Double(count) / 1_000)
    default: String(count)
    }
}
