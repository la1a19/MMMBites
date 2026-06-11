//
//  MemoryMapPreview.swift
//  MMMBites
//
//  Small MapKit preview shown in Memory Detail View. Tap → open in Apple Maps.
//.

import SwiftUI
import MapKit

struct MemoryMapPreview: View {
    let latitude: Double
    let longitude: Double
    let title: String

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(initialPosition: .region(region), interactionModes: []) {
                Marker(title, coordinate: coordinate)
                    .tint(AppColor.primary)
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            .allowsHitTesting(false)

            // Open-in-Maps action button
            Button {
                Haptics.tap()
                openInMaps()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.clash(10, weight: .bold))
                    Text("Open")
                        .font(.clash(10, weight: .semibold))
                }
                .foregroundColor(AppColor.ink)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(AppGradient.glass, in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(7)
        }
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .onTapGesture {
            Haptics.tap()
            openInMaps()
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue
        ])
    }
}

#Preview {
    MemoryMapPreview(
        latitude: -33.8950,
        longitude: 151.2333,
        title: "Centennial Park, Sydney"
    )
    .padding()
}
