import SwiftUI

struct SpeedVPN1View: View {

    @StateObject private var viewModel = SpeedVPN1ViewModel()

    /// Инъекция навигации на экран Tips (из ViewController по паттерну приложения)
    var tipsAction: (() -> Void)?

    private let accentColor = Color(red: 0.879, green: 0.961, blue: 0.496)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                mainSpeedDisplay
                resultsRow
                startTestButton
                tipsButton
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.currentPhase)
        .animation(.easeInOut(duration: 0.15), value: viewModel.liveSpeed)
    }

    // MARK: - Main display

    private var mainSpeedDisplay: some View {
        VStack(spacing: 0) {
            // Полукруглая прогресс-дуга с числом в центре (по паттерну из статьи с ArcShape)
            ZStack(alignment: .center) {
                // Фоновая дуга (верхняя полуокружность 180° → 0°)
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(0))
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .frame(width: 220, height: 110)

                // Активная дуга (прогресс) — trim от 0 до viewModel.progress
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(0))
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                    .frame(width: 220, height: 110)

                // Число + единица поверх дуги
                VStack(alignment: .center, spacing: 0) {
                    Text(String(format: "%.0f", viewModel.mainDisplayValue))
                        .font(.custom("AlbertSans-SemiBold", size: 40))
                        .foregroundStyle(.black)
                    Text("KB/s")
                        .font(.custom("AlbertSans-Medium", size: 20))
                        .foregroundStyle(.gray)
                }
                .offset(y: 30)
                .animation(.easeOut(duration: 0.2), value: viewModel.mainDisplayValue)
            }
            .padding(.top, 24)

            PhaseTitleView()
                .padding(.top, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(.white)
        .cornerRadius(30)
        .shadow(
          color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 23.20
        )
    }

    @ViewBuilder
    private func PhaseTitleView() -> some View {
        switch viewModel.currentPhase {
        case .idle, .downloading:
            Text(viewModel.phaseTitle)
                .font(.custom("AlbertSans-Medium", size: 14))
                .foregroundStyle(.black)
                .padding(10)
                .background(accentColor)
                .cornerRadius(40)
        case .done:
            EmptyView()
        case .uploading:
            Text(viewModel.phaseTitle)
                .font(.custom("AlbertSans-Medium", size: 14))
                .foregroundStyle(accentColor)
                .padding(10)
                .background(Color.black)
                .cornerRadius(40)
        }
    }

    // MARK: - Results (3 columns, visible after test)

    @ViewBuilder
    private var resultsRow: some View {
        if viewModel.currentPhase == .done {
            HStack(spacing: 40) {
                HStack(spacing: 0) {
                    Text("Ping ")
                        .foregroundStyle(Color.black)

                    Text("ms")
                        .foregroundStyle(Color(red: 0.82, green: 0.82, blue: 0.82))

                    HStack(spacing: 8) {
                        Image("pingVpn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)

                        Text("\(viewModel.ping)")
                            .foregroundStyle(Color.black)
                            .font(.custom("AlbertSans-Medium", size: 16))
                    }.padding(.leading, 20)
                }
                .font(.custom("AlbertSans-Medium", size: 16))


                HStack(spacing: 8) {
                    Image("uploadVpn1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text(viewModel.hasUpload ? String(format: "%.0f", viewModel.upload) : "N/A")
                        .foregroundStyle(Color.black)
                        .font(.custom("AlbertSans-Medium", size: 16))
                }

                HStack(spacing: 8) {
                    Image("downloadVpn1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)

                    Text(viewModel.hasDownload ? String(format: "%.0f", viewModel.download) : "N/A")
                        .foregroundStyle(Color.black)
                        .font(.custom("AlbertSans-Medium", size: 16))
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func resultColumn(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("AlbertSans-SemiBold", size: 14))
                .foregroundStyle(.black)
            Text(value)
                .font(.custom("AlbertSans-SemiBold", size: 18))
                .foregroundStyle(.black)
            Text(unit)
                .font(.custom("AlbertSans-Regular", size: 12))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Buttons

    private var startTestButton: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.startTest()
            } label: {
                Text(viewModel.isTesting ? "Testing…" : "Start test")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 50)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(accentColor)
                            .opacity(viewModel.isTesting ? 0.5 : 1)
                    )
                    .overlay(
                      RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.11, green: 0.11, blue: 0.11), lineWidth: 1)
                    )
            }
            .disabled(viewModel.isTesting)

            Text("Check your internet speed")
                .font(.custom("AlbertSans-Medium", size: 16))
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            Text("The speed test results shown in this app are estimates based on your current network conditions. Actual performance may vary depending on your provider, device, and network load.")
                .font(.custom("AlbertSans-Medium", size: 14))
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(20)
                .padding(.top, 16)
        }
    }

    private var tipsButton: some View {
        Button {
            tipsAction?()
        } label: {
            HStack(spacing: 12) {

                Image("tipsVpn1")

                Text("Tips")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)

                Spacer()

                Image("onbForwardVPN1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 32)
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 24))
            .background(.white)
            .cornerRadius(30)
            .shadow(
              color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 23.20
            )

        }
        .disabled(viewModel.isTesting)
        .opacity(viewModel.isTesting ? 0.5 : 1)
    }
}

#Preview {
    SpeedVPN1View()
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Радиус — от ширины, центр — внизу фрейма.
        // Это позволяет рисовать верхнюю полуокружность 180°→0° на полный размер,
        // сохраняя компактную высоту layout (без пустой нижней половины).
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
