//
//  Untitled.swift
//  MMMBites
//
//  Created by Yat Tin lee on 8/6/2026.
//
import SwiftUI

struct MainAlbumsContainerView: View {
    @EnvironmentObject var authViewModel: LoginViewModel
    
    @State private var albums: [Album] = MockData.allAlbums
    
    @State private var albumMemories: [String: [Memory]] = Dictionary(
        uniqueKeysWithValues: MockData.allAlbums.map { album in
            (album.id, MockData.memories(forAlbumId: album.id))
        }
    )
    
    // true = Unlimited board is the main starting page
    // false = AlbumsView is shown
    @State private var showUnlimitedBoard = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if showUnlimitedBoard {
                    UnlimitedMemoryBoardView(
                        albums: albums,
                        albumMemories: $albumMemories,
                        showUnlimitedBoard: $showUnlimitedBoard
                    )
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    AlbumsView(
                        albums: $albums,
                        albumMemories: $albumMemories
                    )
                    .environmentObject(authViewModel)
                    .transition(.opacity)
                    .zIndex(0)
                }
            }
            .animation(.easeInOut(duration: 0.65), value: showUnlimitedBoard)
        }
    }
}
    #Preview {
        MainAlbumsContainerView()
            .environmentObject(LoginViewModel())
    }

