import SwiftUI
import UIKit

struct ServiceVPN1View: View {

    @StateObject private var viewModel: ServiceVPN1ViewModel
    @State private var showManualInput = false
    @State private var manualInputText = ""
    @State private var configNameText = ""
    @State private var showAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""

    init(
        viewModel: ServiceVPN1ViewModel = ServiceVPN1ViewModel()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    Spacer()

                    Button {
                        viewModel.onTapSupport()
                    } label: {
                        Image("supportBtn")
                            .aspectRatio(contentMode: .fit)
                            .shadow(
                              color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 23.20
                            )
                    }
                }

                Button {
                    withAnimation {
                        viewModel.toggleVPN()
                    }
                } label: {
                    Image(viewModel.isConnected ? "vpnOnVPN1" : "vpnOffVPN1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }

                HStack {
                    VStack(spacing: 8) {
                        Text("Received")
                            .font(.custom("AlbertSans-SemiBold", size: 14))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 9)
                            .frame(maxWidth: .infinity)

                        Text(viewModel.formatBytes(viewModel.receivedBytes))
                            .font(.custom("AlbertSans-Regular", size: 14))
                    }

                    if viewModel.isConnected {
                        VStack(spacing: 8) {
                            Text("Connected")
                                .font(.custom("AlbertSans-SemiBold", size: 14))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 9)
                                .background(Color(red: 0.86, green: 0.96, blue: 0.42))
                                .cornerRadius(22)

                            Text(viewModel.formattedConnectionTime())
                                .font(.custom("AlbertSans-Regular", size: 16))
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Sent")
                            .font(.custom("AlbertSans-SemiBold", size: 14))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 9)
                            .frame(maxWidth: .infinity)

                        Text(viewModel.formatBytes(viewModel.sentBytes))
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                }

                if viewModel.servers.isEmpty {
                    emptyStateView
                } else {
                    serversListView
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.custom("AlbertSans-Regular", size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Connection Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showManualInput) {
            AddConfigurationView(
                urlText: $manualInputText,
                nameText: $configNameText,
                onSave: { url, name in
                    showManualInput = false
                    manualInputText = ""
                    configNameText = ""
                    viewModel.importConfiguration(from: url, customName: name)
                },
                onCancel: {
                    showManualInput = false
                    manualInputText = ""
                    configNameText = ""
                }
            )
        }
    }

    // MARK: - Empty state

    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Text("List is empty")
                .font(.custom("AlbertSans-SemiBold", size: 16))

            Text("Add configuration")
                .font(.custom("AlbertSans-SemiBold", size: 20))

            VStack(spacing: 15) {
                Button {
                    viewModel.onTapGetKey()
                } label: {
                    Text("Get Key")
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
                                .stroke(.black, lineWidth: 2)
                        )
                }

                Button {
                    copyFromClipboard()
                } label: {
                    Text("Copy from clipboard")
                        .font(.custom("AlbertSans-SemiBold", size: 16))
                        .foregroundStyle(.black)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.black, lineWidth: 2)
                        )
                }

                Button {
                    showManualInput = true
                } label: {
                    Text("Add manually")
                        .font(.custom("AlbertSans-SemiBold", size: 16))
                        .foregroundStyle(.black)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.black, lineWidth: 2)
                        )
                }
            }
        }
        .padding()
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 30)
        )
    }

    // MARK: - Servers list

    private var serversListView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Servers (\(viewModel.servers.count))")
                    .font(.custom("AlbertSans-SemiBold", size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.hasSavedSubscription {
                    Button {
                        viewModel.refreshSubscription()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                }

                Button {
                    showManualInput = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.servers.enumerated()), id: \.element.sourceURL) { index, server in
                        serverRow(for: server, at: index)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func serverRow(for server: VPNConfiguration, at index: Int) -> some View {
        let isSelected = viewModel.selectedIndex == index

        return Button {
            viewModel.select(at: index)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color(red: 0.55, green: 0.78, blue: 0.25) : .gray)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.decodedRemark(server.remark))
                        .font(.custom("AlbertSans-SemiBold", size: 14))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }

                Spacer()

                Text(server.protocolType.displayName)
                    .font(.custom("AlbertSans-SemiBold", size: 11))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.879, green: 0.961, blue: 0.496))
                    .cornerRadius(8)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.96, green: 0.99, blue: 0.88) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(red: 0.55, green: 0.78, blue: 0.25) : Color.gray.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Loading subscription…")
                    .font(.custom("AlbertSans-SemiBold", size: 14))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.7))
            )
        }
    }

    // MARK: - Actions

    private func copyFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string,
              !clipboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertTitle = "Error"
            alertMessage = "Clipboard is empty"
            showAlert = true
            return
        }
        viewModel.importConfiguration(from: clipboardText)
    }
}

#Preview {
    ServiceVPN1View()
}
