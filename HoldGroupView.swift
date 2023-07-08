//
//  HoldGroupView.swift
//  ClimbCraft
//
//  Created by Benny Kuttler on 3/7/23.
//

import SwiftUI

struct HoldGroupView: View {
    var folder: Folder
    @Binding var selectedHolds: [WallView.TransformedHold]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(folder.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(12)
                
                Text(folder.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(folder.holdGroups, id: \.self) { holdGroup in
                        NavigationLink(destination: HoldView(folder: folder, holdGroup: holdGroup, selectedHolds: $selectedHolds)) {
                            VStack {
                                Image(holdGroup)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(12)
                                
                                Text("\(holdGroup)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}


protocol HoldViewDelegate: AnyObject {
    func didSelectHolds(_ holds: [Folder.Hold?])
}


struct HoldView: View {
    var folder: Folder
    let holdGroup: String // the selected hold group
    @State private var selectedWallImage: UIImage?
    weak var delegate: HoldViewDelegate?
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedHolds: [WallView.TransformedHold]


    
    @State private var holdOverlayPosition: CGPoint = .zero
    @State private var holdOverlayScale: CGFloat = 1.0
    @State private var holdOverlayRotation: Angle = .degrees(0)
    
    var body: some View {
        let folder = FolderList.brands.first { $0.holdGroups.contains(holdGroup) } // find the Folder object that contains the selected hold group
        let holdsForGroup = folder?.holdSubarrays[holdGroup] ?? [] // use holdSubarrays for the selected hold group
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(holdsForGroup, id: \.id) { hold in
                    NavigationLink(destination: WallView(selectedWallImage: selectedWallImage, selectedHoldImage: UIImage(named: hold.name), selectedHold: hold, selectedHolds: selectedHolds).navigationBarBackButtonHidden(true)) {
                        VStack {
                            Image(hold.name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(10)
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                            Text("\(hold.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                    }
                }
            }
            .padding()
            //.navigationBarBackButtonHidden(true)
            .navigationTitle(holdGroup)

        }
    }
}
