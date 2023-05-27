//
//  ViewController.swift
//  ClimbCraft
//
//  Created by Benny Kuttler on 3/6/23.
//

import UIKit
import SwiftUI


struct FolderListView: View {
    var folders: [Folder] = FolderList.brands
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)
            NavigationView {
                List(folders, id: \.id) { folder in
                    NavigationLink(destination: HoldGroupView(folder: folder).navigationBarBackButtonHidden(true), label: {
                        FolderCell(folder: folder)
                    })
                }
                .navigationTitle("Select a Brand")
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                )
            }
        }
    }
}


    
struct FolderCell: View {
    var folder: Folder
    var body: some View {
        HStack {
            Image(folder.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .cornerRadius(4)
                .padding(.vertical, 4)
            
                Text(folder.title)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
        }
        //.background(Color.gray)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FolderListView()
    }
}
