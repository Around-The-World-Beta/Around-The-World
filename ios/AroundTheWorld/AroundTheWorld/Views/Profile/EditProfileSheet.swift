import PhotosUI
import SwiftUI
import UIKit

/// Hinge-style edit sheet: photo, name, city, age, position, 200-character bio.
/// Photo is a local preview only — the API has `avatarUrl` but no upload endpoint.
struct EditProfileSheet: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var city: String = ""
    @State private var age: Int?
    @State private var position: PlayerPosition?
    @State private var bio: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        photoBlock
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 28)

                        fieldLabel(L10n.profileName)
                        textField(text: $name, placeholder: L10n.profileNamePlaceholder)
                            .textInputAutocapitalization(.words)
                            .padding(.bottom, 20)

                        fieldLabel(L10n.profileCity)
                        textField(text: $city, placeholder: L10n.profileCityPlaceholder)
                            .textInputAutocapitalization(.words)
                            .padding(.bottom, 20)

                        fieldLabel(L10n.profileAge)
                        ageRow
                            .padding(.bottom, 20)

                        fieldLabel(L10n.profilePosition)
                        positionGrid
                            .padding(.bottom, 20)

                        fieldLabel(L10n.profileBio)
                        bioEditor
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 96)
                }
            }
        }
        .atwScreenBackground()
        .onAppear(perform: hydrate)
        .onChange(of: pickerItem) { _, item in
            Task { await loadPreview(from: item) }
        }
        .alert(
            L10n.somethingBroke,
            isPresented: Binding(
                get: { session.lastError != nil },
                set: { if !$0 { session.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.lastError = nil }
        } message: {
            Text(session.lastError ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            sheetCloseButton { dismiss() }
                .accessibilityLabel(L10n.authClose)

            Spacer(minLength: 0)

            Text(L10n.profileEditTitle)
                .font(.system(size: 16, weight: .black))
                .textCase(.uppercase)
                .tracking(-0.3)
                .foregroundStyle(AppTheme.foreground)

            Spacer(minLength: 0)

            Button {
                Task { await save() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text(L10n.profileSave)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(AppTheme.primaryForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.gold, in: Capsule())
            }
            .buttonStyle(ATWPressScaleStyle())
            .disabled(session.isWorking)
            .accessibilityLabel(L10n.profileSave)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.card.opacity(0.95))
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    private var photoBlock: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    photoImage
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.primaryForeground)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.gold, in: Circle())
                        .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.profileChangePhoto)

            Text(L10n.profileChangePhoto)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(AppTheme.muted)

            Text(L10n.profilePhotoPending)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private var photoImage: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else if let url = session.profile?.httpAvatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsFallback
                    }
                }
            } else {
                initialsFallback
            }
        }
        .frame(width: 112, height: 112)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.gold, lineWidth: 2))
    }

    private var initialsFallback: some View {
        ProfileAvatarView(
            name: name.isEmpty ? session.user?.displayName : name,
            avatarURL: nil,
            size: 112,
            goldBorder: false,
            signedIn: true
        )
    }

    private var ageRow: some View {
        HStack(spacing: 12) {
            if let current = age {
                Button {
                    if current > 4 { age = current - 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.foreground)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Text("\(current)")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.foreground)
                    .frame(minWidth: 44)

                Button {
                    if current < 99 { age = current + 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.foreground)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            } else {
                Button {
                    age = 18
                } label: {
                    Text(L10n.profileAddAge)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var positionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(PlayerPosition.allCases) { option in
                let active = position == option
                Button {
                    position = option
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(active ? AppTheme.primaryForeground : AppTheme.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            (active ? AppTheme.gold : AppTheme.card),
                            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(active ? AppTheme.gold : AppTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bioEditor: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField(L10n.profileBioPlaceholder, text: $bio, axis: .vertical)
                .lineLimit(4...8)
                .font(.subheadline)
                .foregroundStyle(AppTheme.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .onChange(of: bio) { _, next in
                    if next.count > 200 {
                        bio = String(next.prefix(200))
                    }
                }

            Text(L10n.profileBioCount(bio.count))
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.muted)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(AppTheme.muted)
            .padding(.bottom, 8)
    }

    private func textField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .font(.subheadline)
            .foregroundStyle(AppTheme.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    private func hydrate() {
        name = session.user?.displayName ?? ""
        city = session.profile?.city ?? ""
        age = session.profile?.age
        if let raw = session.profile?.favoritePosition {
            position = PlayerPosition(rawValue: raw)
        }
        bio = session.profile?.bio ?? ""
        session.lastError = nil
    }

    private func loadPreview(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                previewImage = image
            }
        } catch {
            BootLogger.fail("profile.photoPreview", error)
        }
    }

    private func save() async {
        let ok = await session.saveProfile(
            displayName: name,
            city: city,
            age: age,
            position: position?.rawValue,
            bio: bio
        )
        if ok {
            dismiss()
        }
    }
}

func sheetCloseButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "xmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppTheme.foreground)
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
    }
    .buttonStyle(.plain)
}
