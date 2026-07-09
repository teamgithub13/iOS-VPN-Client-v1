import SwiftUI
struct AddConfigurationView: View {
    @Binding var urlText: String
    @Binding var nameText: String
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    private let accentColor = Color(red: 0.879, green: 0.961, blue: 0.496)
    private let borderColor = Color.gray.opacity(0.3)
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: Name field (сверху по дизайну)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("AlbertSans-SemiBold", size: 14))
                        .foregroundStyle(.black)
                    
                    TextField("Enter configuration name", text: $nameText)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(borderColor, lineWidth: 1)
                        )
                }
                .padding()

                // MARK: URL field
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL")
                        .font(.custom("AlbertSans-SemiBold", size: 14))
                        .foregroundStyle(.black)
                    
                    TextField("VLESS, VMess or subscription link", text: $urlText)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                
                // MARK: Bottom buttons
                VStack(spacing: 12) {
                    
                    Button {
                        if let clipboard = UIPasteboard.general.string,
                           !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            urlText = clipboard
                        }
                    } label: {
                        Text("Copy from clipboard")
                            .font(.custom("AlbertSans-SemiBold", size: 16))
                            .foregroundStyle(.black)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.black, lineWidth: 1)
                            )
                    }
                    
                    Button {
                        onSave(urlText, nameText)
                    } label: {
                        Text("Save")
                            .font(.custom("AlbertSans-SemiBold", size: 16))
                            .foregroundStyle(.black)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 50)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.black, lineWidth: 1)
                            )
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding()
                .navigationTitle("Add configuration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }

                Spacer()
            }
        }
    }
}
