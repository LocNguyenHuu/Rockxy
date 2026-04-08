import SwiftUI

/// Application-wide theme selection (System / Light / Dark).
struct AppearanceSettingsTab: View {
    // MARK: Internal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsRow(label: String(localized: "App Theme:")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            themeOption(title: String(localized: "System"), value: "system")
                            themeOption(title: String(localized: "Light"), value: "light")
                            themeOption(title: String(localized: "Dark"), value: "dark")
                        }
                    }
                }
                .onChange(of: appTheme) {
                    AppThemeApplier.apply(appTheme)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
        }
    }

    // MARK: Private

    @AppStorage(RockxyIdentity.current.defaultsKey("appTheme")) private var appTheme = "system"

    private func settingsRow(
        label: String,
        @ViewBuilder content: () -> some View
    )
        -> some View
    {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 160, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.top, 2)
            content()
        }
    }

    private func themeOption(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(value == "dark" ? Color(nsColor: .darkGray) : Color(nsColor: .windowBackgroundColor))
                .frame(width: 100, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            appTheme == value ? Color.accentColor : Color(nsColor: .separatorColor),
                            lineWidth: appTheme == value ? 2 : 1
                        )
                )
                .onTapGesture { appTheme = value }

            HStack(spacing: 5) {
                Circle()
                    .strokeBorder(appTheme == value ? Color.accentColor : Color.gray, lineWidth: 1)
                    .background(Circle().fill(appTheme == value ? Color.accentColor : Color.clear).padding(4))
                    .frame(width: 14, height: 14)
                Text(title)
                    .font(.system(size: 12))
            }
            .onTapGesture { appTheme = value }
        }
    }
}
