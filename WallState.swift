//
//  WallState.swift
//  ClimbCraft
//
//  Created by Benny Kuttler on 4/6/23.
//

import Foundation
import SwiftUI

class WallState: ObservableObject {
    @Published var selectedWallImage: UIImage? = UserDefaults.standard.getImage(forKey: "selectedWallImage")
    @Published var selectedHoldImage: UIImage? = nil
    @Published var selectedHold: Folder.Hold? = nil
}
