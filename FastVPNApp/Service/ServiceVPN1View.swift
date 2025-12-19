import SwiftUI
import UIKit

struct ServiceVPN1View: View {
    
    @StateObject private var viewModel = ServiceVPN1ViewModel()
    @State private var showManualInput = false
    @State private var manualInputText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            VStack(spacing: 30) {
                Text("List is empty")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                
                Text("Add configuration")
                    .font(.custom("AlbertSans-SemiBold", size: 20))
                
                VStack(spacing: 15) {
                    Button {
                        copyFromClipboard()
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
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showManualInput) {
                ManualConfigInputView(
                    text: $manualInputText,
                    onSave: { url in
                        if viewModel.setConfiguration(from: url) {
                            showManualInput = false
                            manualInputText = ""
                        } else {
                            alertMessage = "Неверный формат VPN URL. Поддерживаются: VLESS, VMess, Shadowsocks, WireGuard"
                            showAlert = true
                        }
                    },
                    onCancel: {
                        showManualInput = false
                        manualInputText = ""
                    }
                )
            }
        }
        .padding()
    }
    
    private func copyFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            if viewModel.setConfiguration(from: clipboardText) {
                alertMessage = "Конфигурация успешно добавлена"
                showAlert = true
            } else {
                alertMessage = "Неверный формат VPN URL в буфере обмена. Поддерживаются: VLESS, VMess, Shadowsocks, WireGuard"
                showAlert = true
            }
        } else {
            alertMessage = "Буфер обмена пуст"
            showAlert = true
        }
    }
}

struct ManualConfigInputView: View {
    @Binding var text: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Введите VLESS URL")
                    .font(.custom("AlbertSans-SemiBold", size: 18))
                    .padding(.top)
                
                TextEditor(text: $text)
                    .font(.custom("AlbertSans-Regular", size: 14))
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 200)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Добавить конфигурацию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        onSave(text)
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ServiceVPN1View()
}
