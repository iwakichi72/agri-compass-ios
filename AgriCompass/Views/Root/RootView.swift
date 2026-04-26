import SwiftUI

struct RootView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ToastCenter.self) private var toastCenter
    @State private var showInitialCropSelect = false

    var body: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
            if !userStore.profile.onboardingCompleted {
                OnboardingFlowView(onChooseFirstCrop: {
                    userStore.completeOnboarding()
                    showInitialCropSelect = true
                })
            } else {
                MainTabView()
            }
            ToastOverlay(toasts: toastCenter.items)
        }
        .sheet(isPresented: $showInitialCropSelect) {
            InitialCropSelectionSheet()
        }
    }
}

private struct InitialCropSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CropSelectView()
                .navigationDestination(for: CropRoute.self) { route in
                    CropRouteDestination(route: route)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完了") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
