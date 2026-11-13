import SwiftUI

struct NewProjectSheet: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var template: ProjectTemplate = .starter

    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "NAME / الاسم")

                        TextField("اسم المشروع", text: $name)
                            .font(CyberTheme.arabic(15))
                            .foregroundStyle(CyberTheme.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(CyberTheme.surface)
                            )

                        Text("اتركه فارغاً لاستخدام «\(template.defaultProjectName)».")
                            .font(CyberTheme.arabic(10.5))
                            .foregroundStyle(CyberTheme.textMuted)

                        SectionLabel(text: "TEMPLATE / القالب")

                        ForEach(ProjectTemplate.allCases) { item in
                            Button {
                                template = item
                            } label: {
                                row(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("مشروع جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                    .foregroundStyle(CyberTheme.neonCyan)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    create()
                } label: {
                    Label("إنشاء وفتح", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(filled: true))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CyberTheme.background)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ item: ProjectTemplate) -> some View {
        HStack(spacing: 11) {
            Image(systemName: item.icon)
                .font(.system(size: 15))
                .foregroundStyle(item == template ? CyberTheme.neonGreen : CyberTheme.textSecondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(
                        (item == template ? CyberTheme.neonGreen : CyberTheme.textSecondary).opacity(0.10)
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(CyberTheme.arabic(14, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                Text(item.subtitle)
                    .font(CyberTheme.arabic(10.5))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            if item == template {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CyberTheme.neonGreen)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CyberTheme.surface.opacity(item == template ? 1 : 0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(item == template ? CyberTheme.neonGreen.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? template.defaultProjectName : trimmed
        app.createProject(named: finalName, template: template)
        dismiss()
    }
}
