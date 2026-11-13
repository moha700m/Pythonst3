import SwiftUI

/// Shows exactly what the assistant wants to change before anything touches disk.
struct DiffApprovalView: View {
    @EnvironmentObject private var app: AppModel

    let proposal: CodeProposal
    private let diff: [DiffLine]
    private let counts: (inserted: Int, removed: Int)

    init(proposal: CodeProposal) {
        self.proposal = proposal
        let lines = LineDiff.compute(old: proposal.previousContent, new: proposal.proposedContent)
        self.diff = lines
        self.counts = LineDiff.counts(lines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(diff) { line in
                                DiffLineRow(line: line)
                            }
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("مراجعة التعديل")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { actions }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundStyle(CyberTheme.neonCyan)
                Text(proposal.path)
                    .font(CyberTheme.mono(12, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text("+\(counts.inserted)")
                    .font(CyberTheme.mono(11, weight: .bold))
                    .foregroundStyle(CyberTheme.neonGreen)
                Text("-\(counts.removed)")
                    .font(CyberTheme.mono(11, weight: .bold))
                    .foregroundStyle(CyberTheme.danger)
            }

            Text("اقتراح «\(proposal.summary)». لن يُحفظ أي تغيير قبل الضغط على «تطبيق».")
                .font(CyberTheme.arabic(11))
                .foregroundStyle(CyberTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CyberTheme.surface.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberTheme.neonCyan.opacity(0.16))
                .frame(height: 0.5)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                app.applyPendingProposal()
            } label: {
                Label("تطبيق", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(filled: true))

            Button {
                app.discardPendingProposal()
            } label: {
                Text("إلغاء")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(tint: CyberTheme.textSecondary))
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(CyberTheme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CyberTheme.neonGreen.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Text(marker)
                .frame(width: 9, alignment: .center)

            Text(number)
                .frame(width: 28, alignment: .trailing)

            Text(line.text.isEmpty ? " " : line.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(CyberTheme.mono(10.5))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(background)
    }

    private var marker: String {
        switch line.kind {
        case .insert: return "+"
        case .delete: return "−"
        case .equal: return " "
        }
    }

    private var number: String {
        if let new = line.newNumber { return "\(new)" }
        if let old = line.oldNumber { return "\(old)" }
        return ""
    }

    private var color: Color {
        switch line.kind {
        case .insert: return CyberTheme.neonGreen
        case .delete: return CyberTheme.danger
        case .equal: return CyberTheme.textSecondary
        }
    }

    private var background: Color {
        switch line.kind {
        case .insert: return CyberTheme.neonGreen.opacity(0.10)
        case .delete: return CyberTheme.danger.opacity(0.10)
        case .equal: return .clear
        }
    }
}
