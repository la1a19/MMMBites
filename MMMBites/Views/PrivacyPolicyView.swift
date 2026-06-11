//
//  PRIVACYPOLICYVIEW.swift
//  MMMBites
//
//  Created by Yat Tin lee on 10/6/2026.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let effectiveDate = "[Insert date]"

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    headerCard

                    policySection(
                        title: "1. Information We Collect",
                        body: """
                        mmmbite may collect the following types of information:

                        Account information

                        When users register or sign in, mmmbite collects account information such as:

                        Email address; username or display name; Firebase user ID; authentication status; and account creation or login-related records.

                        This information is used to identify the user account and allow secure sign-in through Firebase Authentication.

                        User-uploaded photos

                        Users may upload photos to mmmbite. These photos are stored in Cloud Firestore as part of the app’s photo-memory feature.

                        Uploaded photos may be connected to the user’s account because the app needs to know who uploaded the photo and who is allowed to access it.

                        Photo and memory metadata

                        mmmbite may store information related to uploaded photos, such as:

                        Uploader user ID; upload date and time; captions or descriptions; album or memory information; friend-sharing permissions; and access-control information.

                        Friend and sharing information

                        To support private sharing, mmmbite stores friend-related information, such as:

                        Friend requests; accepted friend relationships; shared users; and records showing which users can view specific uploaded photos.

                        This information is necessary because mmmbite only allows photos to be shared with approved friend accounts.
                        """
                    )

                    policySection(
                        title: "2. How We Use Information",
                        body: """
                        mmmbite uses collected information to:

                        Create and manage user accounts; allow users to sign in; store uploaded photos; show users their own uploaded photos; allow users to share selected photos with approved friends; control access to private photo memories; manage friend relationships; protect user data from unauthorised access; and maintain the basic function of the app.

                        mmmbite does not sell user data.

                        mmmbite does not use uploaded photos for advertising.

                        mmmbite does not make uploaded photos publicly available by default.
                        """
                    )

                    policySection(
                        title: "3. How Photo Sharing Works",
                        body: """
                        Photos uploaded to mmmbite are intended to be private.

                        Uploaded photos may be accessed only by:

                        The user who uploaded the photo; other users who have been added or accepted as friends; and users who have been granted access through mmmbite’s sharing system.

                        Access is controlled through Firebase Authentication and Cloud Firestore Security Rules.
                        """
                    )

                    policySection(
                        title: "4. Third-Party Data Processing",
                        body: """
                        mmmbite uses Firebase, a Google service, to provide backend app functions.

                        Because mmmbite uses Firebase Authentication and Cloud Firestore, some user information is processed by Google Firebase to provide authentication, database storage, security, and app operation services.
                        """
                    )

                    policySection(
                        title: "5. Data Linked to User Identity",
                        body: """
                        The following data may be linked to a user’s identity:

                        Email address; username or display name; Firebase user ID; uploaded photos; captions or memory content; friend relationships; and sharing permissions.
                        """
                    )

                    policySection(
                        title: "6. Data Sharing",
                        body: """
                        mmmbite does not sell personal data.

                        mmmbite does not share uploaded photos publicly.

                        User data may be processed by Firebase / Google as the backend service provider for authentication, database storage, and app operation.

                        Photos are shared only according to the app’s friend-sharing function. This means a user’s uploaded photos may be shown to other users only when those users are approved friends or have permission through the app.
                        """
                    )

                    policySection(
                        title: "7. User Control and Deletion",
                        body: """
                        Users can control what photos they upload and which friends they share with.

                        Where supported by the app, users may delete uploaded photos or remove sharing access.

                        Users may request account or data deletion by contacting:

                        placeholder@gmail.com

                        After receiving a deletion request, mmmbite will make reasonable efforts to delete or anonymise the user’s account data, uploaded photos, friend records, and related Firestore data, unless retention is required for legal, security, or technical reasons.
                        """
                    )

                    policySection(
                        title: "8. Children’s Privacy",
                        body: """
                        mmmbite is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided personal information, we will take reasonable steps to delete that information.
                        """
                    )

                    policySection(
                        title: "9. Changes to This Privacy Policy",
                        body: """
                        mmmbite may update this Privacy Policy when the app changes, when Firebase services change, or when privacy requirements change.

                        Any updated version will include a new effective date.
                        """
                    )

                    policySection(
                        title: "10. Contact",
                        body: """
                        For privacy questions or data deletion requests, contact:

                        App: mmmbite
                        Developer: Handshake Minions
                        Email: placeholder@gmail.com
                        """
                    )
                }
                .padding(AppSpacing.xl)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Privacy Policy for mmmbite")
                .font(AppFont.headline)
                .foregroundColor(AppColor.ink)

            VStack(alignment: .leading, spacing: 4) {
                Text("Effective date: \(effectiveDate)")
                Text("App name: mmmbite")
                Text("Developer: Handshake Minions")
                Text("Contact: placeholder@gmail.com")
            }
            .font(AppFont.caption)
            .foregroundColor(AppColor.inkMuted)

            Divider()
                .padding(.vertical, 4)

            Text("mmmbite is a private photo-memory sharing app. The app allows users to create an account, upload photos, and share selected photo memories only with other accounts they have added or accepted as friends.")
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.ink)

            Text("This Privacy Policy explains what information mmmbite collects, how it is used, and how it is stored.")
                .font(AppFont.subheadline)
                .foregroundColor(AppColor.ink)
        }
        .padding(AppSpacing.l)
        .background(
            AppGradient.glass,
            in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(title)
                .font(.clash(16, weight: .semibold))
                .foregroundColor(AppColor.ink)

            Text(body)
                .font(.clash(13, weight: .regular))
                .foregroundColor(AppColor.inkMuted)
                .lineSpacing(4)
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.72),
            in: RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
