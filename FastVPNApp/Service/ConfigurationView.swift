import SwiftUI
struct ConfigurationView: View {

    let onChangeConfig: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    private let accentColor = Color(red: 0.879, green: 0.961, blue: 0.496)
    private let borderColor = Color.gray.opacity(0.3)

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: Bottom buttons
                VStack(spacing: 16) {

                    Button {
                        onChangeConfig()
                    } label: {
                        HStack(spacing: 4) {
                            Image("changeConfigVPN1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.black)

                            Text("Change Configuration")
                                .font(.custom("AlbertSans-SemiBold", size: 16))
                                .foregroundStyle(.black)
                        }
                    }
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

                    Button {
                        onDelete()
                    } label: {
                        HStack(spacing: 4) {
                            Image("deleteConfigVPN1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.black)

                            Text("Delete")
                                .font(.custom("AlbertSans-SemiBold", size: 16))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.black, lineWidth: 1)
                    )
                }
                .padding()
                .navigationTitle("Configuration")
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
