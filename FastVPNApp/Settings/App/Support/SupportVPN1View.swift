import SwiftUI

struct SupportVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
    @State private var feedbackVPN1 = ""
    @State private var descriptionVPN1 = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                HStack {
                    Button {
                        dismissVPN1Action?()
                    } label: {
                        Image("dismissVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    
                    Spacer()
                }
                
                Text("Support")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            VStack {
                Text("How can we contact you with feedback?")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("", text: $feedbackVPN1)
                    .padding()
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack {
                Text("Describe the problem you are facing or ask your question")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $descriptionVPN1)
                    .padding()
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 250)
            }
            
            Button {
                if !feedbackVPN1.isEmpty, !descriptionVPN1.isEmpty {
                    dismissVPN1Action?()
                }
            } label: {
                Text("Send")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)
                    .frame(width: 140, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.black, lineWidth: 2)
                    )
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            UIApplication.shared.hideKeyboardVPN1()
        }
    }
}

extension UIApplication {
    func hideKeyboardVPN1() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SupportVPN1View()
}
