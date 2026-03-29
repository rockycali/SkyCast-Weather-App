import SwiftUI

struct WeatherButton: View {
    let title: LocalizedStringKey
    let textColor: Color
    let backgroundColor: Color

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    WeatherButton(title: "Search", textColor: .black, backgroundColor: .white)
        .padding()
        .background(Color.blue)
}
