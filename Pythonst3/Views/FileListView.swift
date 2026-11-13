import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var showNewFile = false
    @State private var newFileName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.files) { file in
                    Button {
                        app.selectFile(file.path)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(CyberTheme.neonCyan)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(file.path)
                                    .font(CyberTheme.mono(13))
                                    .foregroundStyle(CyberTheme.textPrimary)
                                Text("\(file.content.count) حرفاً")
                                    .font(CyberTheme.mono(9))
                                    .foregroundStyle(CyberTheme.textMuted)
                            }
                            Spacer()
                            if file.isEntrypoint {
                                Text("البداية")
                                    .font(CyberTheme.mono(9, weight: .semibold))
                                    .foregroundStyle(CyberTheme.neonGreen)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(CyberTheme.neonGreen.opacity(0.10)))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(CyberTheme.surface)
                    .swipeActions {
                        if !file.isEntrypoint {
                            Button(role: .destructive) {
                                app.deleteFile(file)
                            } label: {
                                Label("حذف", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CyberTheme.background)
            .navigationTitle("ملفات المشروع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewFile = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(CyberTheme.neonGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("تم") {
                        dismiss()
                    }
                    .foregroundStyle(CyberTheme.neonCyan)
                }
            }
            .alert("ملف جديد", isPresented: $showNewFile) {
                TextField("utils.py", text: $newFileName)
                Button("إنشاء") {
                    let name = newFileName
                    newFileName = ""
                    app.createFile(named: name)
                }
                Button("إلغاء", role: .cancel) {
                    newFileName = ""
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
