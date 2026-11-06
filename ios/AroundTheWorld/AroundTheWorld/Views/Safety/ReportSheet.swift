import SwiftUI

/// Report a game's notes or a host. Small sheet — does not rebuild Game Detail.
struct ReportSheet: View {
    let targetType: ReportTargetType
    let targetId: UUID
    var onFinished: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .inappropriate
    @State private var details: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private let api = AroundTheWorldAPI()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    sheetCloseButton { dismiss() }
                        .accessibilityLabel(L10n.authClose)
                    Spacer(minLength: 0)
                    Text(L10n.reportTitle)
                        .font(.system(size: 16, weight: .black))
                        .textCase(.uppercase)
                        .tracking(-0.3)
                        .foregroundStyle(AppTheme.foreground)
                    Spacer(minLength: 0)
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.card.opacity(0.95))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppTheme.border).frame(height: 1)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.reportSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)

                        VStack(spacing: 8) {
                            ForEach(ReportReason.allCases) { option in
                                Button {
                                    reason = option
                                } label: {
                                    HStack {
                                        Text(option.label)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.foreground)
                                        Spacer()
                                        if reason == option {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(AppTheme.gold)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        AppTheme.card,
                                        in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                                            .stroke(reason == option ? AppTheme.gold : AppTheme.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .trailing, spacing: 6) {
                            TextField(L10n.reportDetailsPlaceholder, text: $details, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.foreground)
                                .padding(12)
                                .background(
                                    AppTheme.card,
                                    in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                                .onChange(of: details) { _, next in
                                    if next.count > UserContentLimits.reportDetailsMax {
                                        details = UserContentLimits.clamped(next, maxLength: UserContentLimits.reportDetailsMax)
                                    }
                                }

                            Text("\(details.count)/\(UserContentLimits.reportDetailsMax)")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.muted)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Group {
                                if isSending {
                                    ProgressView().tint(AppTheme.primaryForeground)
                                } else {
                                    Text(L10n.reportSubmit)
                                }
                            }
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppTheme.primaryForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 96)
                }
            }
        }
        .atwScreenBackground()
        .alert(L10n.somethingBroke, isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func submit() async {
        isSending = true
        defer { isSending = false }
        do {
            let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await api.createReport(
                CreateReportRequest(
                    targetType: targetType,
                    targetId: targetId,
                    reason: reason,
                    details: trimmed.isEmpty ? nil : trimmed
                )
            )
            onFinished(L10n.reportThanks)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
