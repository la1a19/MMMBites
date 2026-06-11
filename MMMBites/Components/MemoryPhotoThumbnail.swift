//
//  MemoryPhotoThumbnail.swift
//  MMMBites
//

import SwiftUI

struct MemoryPhotoThumbnail: View {
    let photoData: [Data]
    let imageURLs: [String]
    let width: CGFloat
    let height: CGFloat
    var isCircle = true
    var placeholderSystemImage = "photo.fill"
    
    var body: some View {
        Group {
            if isCircle {
                thumbnailContent
                    .frame(width: width, height: height)
                    .clipShape(Circle())
            } else {
                thumbnailContent
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let data = photoData.first,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let urlString = imageURLs.first,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            if isCircle {
                Circle().fill(AppGradient.glass)
            } else {
                RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
                    .fill(AppGradient.glass)
            }

            Image(systemName: placeholderSystemImage)
                .font(.clash(22, weight: .semibold))
                .foregroundColor(AppColor.inkFaint)
        }
    }
}
