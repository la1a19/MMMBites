//
//  Toast.swift
//  MMMBites
//
//  Lightweight global toast system for surfacing errors / success / info
//  messages. Use `ToastCenter.shared.showError("…")` from anywhere.
//

import SwiftUI
import Combine

enum ToastKind {
    case error, success, info

    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var background: Color {
        switch self {
        case .error: return AppColor.primary
        case .success: return .green.opacity(0.92)
        case .info: return .blue.opacity(0.92)
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let kind: ToastKind

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published var current: ToastMessage?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func showError(_ message: String) {
        show(ToastMessage(message: message, kind: .error))
    }

    func showSuccess(_ message: String) {
        show(ToastMessage(message: message, kind: .success))
    }

    func showInfo(_ message: String) {
        show(ToastMessage(message: message, kind: .info))
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(AppAnimation.snappy) {
            current = nil
        }
    }

    private func show(_ toast: ToastMessage) {
        dismissTask?.cancel()
        withAnimation(AppAnimation.bouncy) {
            current = toast
        }
        Haptics.warning()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(AppAnimation.snappy) {
                    self?.current = nil
                }
            }
        }
    }
}

struct ToastView: View {
    let toast: ToastMessage
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: toast.kind.icon)
                    .font(.clash(15, weight: .bold))
                    .foregroundColor(.white)

                Text(toast.message)
                    .font(.clash(14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(toast.kind.background, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// Overlay this on the app root to render whatever the ToastCenter is showing.
struct ToastOverlay: View {
    @ObservedObject private var center = ToastCenter.shared

    var body: some View {
        VStack {
            if let toast = center.current {
                ToastView(toast: toast) {
                    center.dismiss()
                }
                .padding(.horizontal, 20)
                .transition(
                    .move(edge: .top)
                    .combined(with: .opacity)
                )
            }
            Spacer()
        }
        .padding(.top, 8)
        .animation(AppAnimation.snappy, value: center.current)
        .allowsHitTesting(center.current != nil)
    }
}
