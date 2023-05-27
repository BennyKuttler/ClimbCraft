//  ClimbCraft
//
//  Created by Benny Kuttler on 3/7/23.
//

import SwiftUI
import UIKit
import simd




struct WallView: View {
    
    enum EditMode {
        case none
        /*case size
        case position
        case rotation*/
        case orientation
    }

    
    // MARK: - Properties
    @State private var selectedWallImage: UIImage?
    var selectedHoldImage: UIImage?
    @State private var holdOverlayPosition: CGPoint = .zero
    @State private var holdOverlayScale: CGFloat = 1.0
    @State private var holdOverlayRotation: Angle = .degrees(0)
    @State private var selectedHold: Folder.Hold?
    @State private var scale = 1.0
    @State private var lastScale = 1.0
    private let minScale = 1.0
    private let maxScale = 5.0
    @State var isDragging = false
    @State private var selectedWallPosition: CGPoint = .zero
    @State private var editMode: EditMode = .orientation
    @State private var showConfirmationAlert = false
    @State private var showEditModeActionSheet = false
    @State private var showSelectWallAlert = false
    @State private var navViewKey = UUID()

    
    
    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { state in
                adjustScale(from: state)
            }
            .onEnded { state in
                withAnimation {
                    validateScaleLimits()
                }
                lastScale = 1.0
            }
    }
    
    @State var offset = CGSize.zero
    @State var newOffset = CGSize.zero
    
    var wallDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                let screenSize = UIScreen.main.bounds.size
                let imageWidth = self.selectedWallImage!.size.width * CGFloat(scale)
                let imageHeight = self.selectedWallImage!.size.height * CGFloat(scale)

                // if the image is smaller or equal to the screen, we center the image
                if (imageWidth <= screenSize.width && imageHeight <= screenSize.height) {
                    self.newOffset = CGSize.zero
                    return
                }

                // calculate the overflow for width and height
                let widthOverflow = max(imageWidth - screenSize.width, 0) / 2
                let heightOverflow = max(imageHeight - screenSize.height, 0) / 2

                // prevent the image from being dragged beyond its edges
                let xOffset = min(max(value.translation.width + self.offset.width, -widthOverflow), widthOverflow)
                let yOffset = min(max(value.translation.height + self.offset.height, -heightOverflow), heightOverflow)

                self.newOffset = CGSize(width: xOffset, height: yOffset)
            }
            .onEnded { _ in
                self.offset = self.newOffset
            }
    }






    
    // MARK: - Initializer
    init(selectedWallImage: UIImage? = nil, selectedHoldImage: UIImage?, selectedHold: Folder.Hold?) {
        _selectedWallImage = State(initialValue: selectedWallImage)
        self.selectedHoldImage = selectedHoldImage
        _selectedHold = State(initialValue: selectedHold)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                if let image = selectedWallImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(CGFloat(scale))
                        .offset(x: self.newOffset.width, y: self.newOffset.height)
                        .gesture(self.wallDrag)
                        .gesture(magnification)
                }

                if let selectedHold = selectedHold, editMode != .none {
                    Image(selectedHold.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .position(holdOverlayPosition)
                        .scaleEffect(holdOverlayScale)
                        .rotationEffect(holdOverlayRotation)
                        .simultaneousGesture(TapGesture().onEnded {
                            if editMode != .none {
                                showConfirmationAlert = true
                            } else {
                                showEditModeActionSheet = true
                            }
                        })
                        .gesture(editMode == .orientation ? SimultaneousGesture(dragGesture(), SimultaneousGesture(rotationGesture(), scaleGesture())) : nil)
                       /* .gesture(editMode == .rotation ? rotationGesture() : nil)
                        .gesture(editMode == .size ? scaleGesture() : nil) */
                        // ...
                        .alert(isPresented: $showConfirmationAlert) {
                            Alert(
                                title: Text("Are you sure this is the correct orientation of your hold?"),
                                primaryButton: .default(Text("Confirm")) {
                                   /* if editMode == .size {
                                        editMode = .position
                                    } else if editMode == .position {
                                        editMode = .rotation
                                    }*/ if editMode == .orientation {
                                        // Call the mergeImages function to merge the hold and the wall image
                                        if let holdImage = UIImage(named: selectedHold.name), let wallImage = selectedWallImage {
                                            let mergedImage = mergeImages(baseImage: wallImage, holdImage: holdImage, screenSize: UIScreen.main.bounds.size)

                                            selectedWallImage = mergedImage
                                        }
                                        editMode = .none
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    CustomTitleView(title: selectedWallImage == nil ? "Add a picture of a wall" : (selectedHold == nil ? "Add holds to the wall" : "Tap the hold to confirm"), fontSize: 10)

                }
            }


          //  .overlay(selectedHoldOverlay())
            .navigationBarBackButtonHidden(true)
            //.navigationBarHidden(true)
            .navigationBarItems(
                leading: Button(action: addWallButtonTapped) {
                    Text(selectedWallImage == nil ? "Add Wall" : "Change Wall")
                        .bold()
                        .foregroundColor(.blue)
                },
                trailing: Button(action: addHoldsButtonTapped) {
                    Text("Add Holds")
                        .bold()
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedWallImage: $selectedWallImage)
            }
            
            //Look here to re-add back button if needed
            .background(
                            NavigationLink(
                                "",
                                destination: FolderListView().navigationBarBackButtonHidden(true),
                                isActive: $showingFolderList
                            )
                            .opacity(0)
                        )
                        .onChange(of: selectedHoldImage, perform: { value in
                            if value != nil {
                                selectedWallImage = value
                            }
                            if value == nil {
                                self.navViewKey = UUID()
                            }
                        })
                        .onAppear {
                            // Load selectedWallImage on Appear
                            selectedWallImage = UserDefaults.standard.getImage(forKey: "selectedWallImage")
                        }
                        .onDisappear {
                            // Save selectedWallImage on Disappear
                            if let selectedWallImage = selectedWallImage {
                                UserDefaults.standard.setImage(selectedWallImage, forKey: "selectedWallImage")
                            }
                            
                        }
                    }
        .id(navViewKey)

    }
    
    // MARK: - Actions
    private func addWallButtonTapped() {
        showingImagePicker = true
    }
    
    private func addHoldsButtonTapped() {
        showingFolderList = true
    }
    
    func adjustScale(from state: MagnificationGesture.Value) {
        let delta = state / lastScale
        scale *= delta
        lastScale = state
    }
    func getMinimumScaleAllowed() -> CGFloat {
        return max(scale, minScale)
    }
    func getMaximumScaleAllowed() -> CGFloat {
        return min(scale, maxScale)
    }
    func validateScaleLimits() {
        scale = getMinimumScaleAllowed()
        scale = getMaximumScaleAllowed()
    }
    
    
    // MARK: - State
    @State private var showingImagePicker = false
    @State private var showingFolderList = false
    
    
    // MARK: - Gestures
    func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let newScale = holdOverlayScale * scale.magnitude
                if newScale >= 1.0 {
                    holdOverlayScale = newScale
                }
            }
    }
    
    // Add a new function to merge the hold image with the wall image
    func mergeImages(baseImage: UIImage, holdImage: UIImage, screenSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(baseImage.size, false, 0.0)
        baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
        
        let scaleFactor = baseImage.size.width / screenSize.width

        let holdNormalizedPosition = CGPoint(x: holdOverlayPosition.x, y: holdOverlayPosition.y)
        let holdNormalizedSize = CGSize(width: holdImage.size.width * scaleFactor, height: holdImage.size.height * scaleFactor)
        let holdRect = CGRect(origin: holdNormalizedPosition, size: holdNormalizedSize)
        
        // Preserve the position, rotation, and size of the hold
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        // Translate the context to the hold's position
        context.translateBy(x: holdNormalizedPosition.x, y: holdNormalizedPosition.y)
        
        // Rotate the context by the hold's rotation
        context.rotate(by: CGFloat(holdOverlayRotation.radians))
        
        // Translate the context back
        //context.translateBy(x: -holdNormalizedPosition.x, y: -holdNormalizedPosition.y)
        
        // Draw the hold image with the modified context
        holdImage.draw(in: holdRect, blendMode: .normal, alpha: 1.0)
        
        // Restore the context
        context.restoreGState()
        
        selectedHold = nil
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }





}

extension WallView {
    
    func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                let deltaX = value.location.x - value.startLocation.x
                let deltaY = value.location.y - value.startLocation.y

                let scaledDeltaX = deltaX / holdOverlayScale
                let scaledDeltaY = deltaY / holdOverlayScale

                let angle = -holdOverlayRotation.radians
                let cosAngle = cos(angle)
                let sinAngle = sin(angle)

                let rotatedDeltaX = scaledDeltaX * cosAngle - scaledDeltaY * sinAngle
                let rotatedDeltaY = scaledDeltaX * sinAngle + scaledDeltaY * cosAngle

                holdOverlayPosition = CGPoint(x: value.startLocation.x + CGFloat(rotatedDeltaX),
                                              y: value.startLocation.y + CGFloat(rotatedDeltaY))
            }
    }
    
    func rotationGesture() -> some Gesture {
        RotationGesture()
            .onChanged { value in
                holdOverlayRotation = value
            }
            .onEnded { value in
            holdOverlayRotation = value
            }
    }
    
    func scaleGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = min(maxScale, Double(value.magnitude) * lastScale)
                holdOverlayScale = CGFloat(newScale)
            }
            .onEnded { _ in
                lastScale = Double(holdOverlayScale)
            }
    }
}

extension UserDefaults {
    func setImage(_ image: UIImage?, forKey key: String) {
        guard let image = image else { return set(nil, forKey: key) }
        set(image.pngData(), forKey: key)
    }
    
    func getImage(forKey key: String) -> UIImage? {
        guard let data = data(forKey: key), let image = UIImage(data: data) else { return nil }
        return image
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedWallImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = .photoLibrary
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedWallImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension CGSize: Comparable {
    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width < rhs.width && lhs.height < rhs.height
    }
    
    public static func == (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

struct CustomTitleView: View {
    let title: String
    let fontSize: CGFloat
    
    var body: some View {
        Text(title)
            .font(.system(size: fontSize))
            .bold()
    }
}
