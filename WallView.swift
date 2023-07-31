//  ClimbCraft
//
//  Created by Benny Kuttler on 3/7/23.
//

import SwiftUI
//import UIKit
//import simd

struct WallView: View {
    enum EditMode {
        case none
        /*case size
        case position
        case rotation*/
        case orientation
    }
    
    // A struct that represents a hold and its transformations
    struct TransformedHold {
        var hold: Folder.Hold
        var position: CGPoint
        var scale: CGFloat
        var rotation: Angle
        var origin: CGPoint  // new line here

        // Additional property to store position vector
        var positionVector: CGVector {
            get {
                return CGVector(dx: position.x - origin.x, dy: position.y - origin.y)
            }
            set {
                position = CGPoint(x: origin.x + newValue.dx, y: origin.y + newValue.dy)
            }
        }
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
    private let minScale = 0.2
    private let maxScale = 1.0
    @State var isDragging = false
    @State private var selectedWallPosition: CGPoint = .zero
    @State private var editMode: EditMode = .orientation
    @State private var showConfirmationAlert = false
    @State private var showEditModeActionSheet = false
    @State private var showSelectWallAlert = false
    @State private var navViewKey = UUID()
    @State private var selectedHolds: [TransformedHold] = []

    @State private var selectedIndex: Int?
    

    @State private var lastPosition = CGPoint.zero
    @State private var centerPosition = CGPoint.zero
    
    @State var offset = CGSize.zero
    @State var newOffset = CGSize.zero
    
    @State var initialPositions: [CGPoint] = []

    @State var centerOfView = CGSize.zero

    @State private var screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    @State private var origin: CGPoint = .zero
    @State private var initialLoad = true

    
    var wallCenterPosition: CGPoint {
        guard let image = selectedWallImage else { return .zero }
        let x = selectedWallPosition.x + (image.size.width * CGFloat(scale)) / 2
        let y = selectedWallPosition.y + (image.size.height * CGFloat(scale)) / 2
        return CGPoint(x: x, y: y)
    }
    
    // Computed property for the center position of the wall image


   /* var wallDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if initialPositions.isEmpty {
                    initialPositions = selectedHolds.map { $0.position }
                }

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
                
                // Update the position of each hold to move with the wall
                for index in selectedHolds.indices {
                    let deltaX = value.location.x - value.startLocation.x
                    let deltaY = value.location.y - value.startLocation.y

                    let scaledDeltaX = deltaX / selectedHolds[index].scale
                    let scaledDeltaY = deltaY / selectedHolds[index].scale

                    let angle = -selectedHolds[index].rotation.radians
                    let cosAngle = cos(angle)
                    let sinAngle = sin(angle)

                    let rotatedDeltaX = scaledDeltaX * cosAngle - scaledDeltaY * sinAngle
                    let rotatedDeltaY = scaledDeltaX * sinAngle + scaledDeltaY * cosAngle

                    selectedHolds[index].position = CGPoint(
                        x: initialPositions[index].x + CGFloat(rotatedDeltaX),
                        y: initialPositions[index].y + CGFloat(rotatedDeltaY)
                    )
                    
                }
            }
            .onEnded { _ in
                self.offset = self.newOffset
                self.initialPositions = []
                // Update the origin of each hold to its final position after the drag
                for index in selectedHolds.indices {
                    selectedHolds[index].origin = selectedHolds[index].position
                }
            }

    }
    */

    //@State private var screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)

    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { state in
            
                
                let scalingFactor = state / lastScale
                scale *= scalingFactor

                // Update the scaling and position of each hold to scale with the wall
                for index in selectedHolds.indices {
                    var hold = selectedHolds[index]
                    hold.scale *= CGFloat(scalingFactor)
                    
                    let scaledholdPositionVector = CGVector(dx: scalingFactor * (hold.origin.x - wallCenterPosition.x), dy: scalingFactor * (hold.origin.y - wallCenterPosition.y))
                    
                    let realHoldPositionVector = CGPoint(x: scaledholdPositionVector.dx + wallCenterPosition.x, y: scaledholdPositionVector.dy + wallCenterPosition.y)
                    
                    hold.position = CGPoint(x: realHoldPositionVector.x / scalingFactor, y: realHoldPositionVector.y / scalingFactor)
                    
                    // Update the hold in the array
                    selectedHolds[index] = hold
                }
                lastScale = state
            }
            .onEnded { state in
                withAnimation {
                    validateScaleLimits()
                }
                lastScale = 1.0
            }
    }

    // MARK: - Initializer
    init(selectedWallImage: UIImage? = nil, selectedHoldImage: UIImage?, selectedHold: Folder.Hold?, selectedHolds: [TransformedHold] = []) {
        _selectedWallImage = State(initialValue: selectedWallImage)
        self.selectedHoldImage = selectedHoldImage
        _selectedHold = State(initialValue: selectedHold)
        _selectedHolds = State(initialValue: selectedHolds)
    }

    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    if let image = selectedWallImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(CGFloat(scale))
                            .offset(x: self.newOffset.width, y: self.newOffset.height)
                            //.gesture(self.wallDrag)
                            .gesture(magnification)
                    }
                    
                    ForEach(selectedHolds.indices, id: \.self) { index in
                        let transformedHold = selectedHolds[index]
                        Image(transformedHold.hold.name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .position(transformedHold.position)
                            .scaleEffect(transformedHold.scale)
                            .rotationEffect(transformedHold.rotation)
                            .onTapGesture {
                                if selectedHold == nil {
                                    selectedHold = transformedHold.hold
                                    holdOverlayPosition = transformedHold.position
                                    holdOverlayScale = transformedHold.scale
                                    holdOverlayRotation = transformedHold.rotation
                                    showConfirmationAlert = true
                                }
                            }
                    }
                    
                    if let currentSelectedHold = selectedHold, editMode != .none {
                        Image(currentSelectedHold.name)
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
                        //Needs to be fixed
                            .alert(isPresented: $showConfirmationAlert) {
                                Alert(
                                    title: Text("Would you like to edit the orientation of this hold?"),
                                    primaryButton: .default(Text("Confirm")) {
                                        if editMode == .orientation {
                                            let newHold = TransformedHold(hold: selectedHold!, position: holdOverlayPosition, scale: holdOverlayScale, rotation: holdOverlayRotation, origin: origin)
                                            
                                            selectedHolds.append(newHold)
                                            selectedHold = nil
                                            holdOverlayPosition = .zero
                                            holdOverlayScale = 1.0
                                            holdOverlayRotation = .degrees(0)
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        
                        
                        
                    }
                }
                
                /*VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                withAnimation {
                                    // Increase the scale
                                    let newScale = scale + 0.5
                                    let scalingFactor = newScale / scale
                                    scale = newScale
                                    updatePositionsAndScaleAfterMagnification(scalingFactor: scalingFactor)
                                }
                            }) {
                                Image("magnify_plus")  // Assumes that you have an image named 'magnify_plus'
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .padding()
                                    .background(Color.gray.opacity(0.6))
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                withAnimation {
                                    // Decrease the scale
                                    let newScale = max(scale - 0.5, 1.0)
                                    let scalingFactor = newScale / scale
                                    scale = newScale
                                    updatePositionsAndScaleAfterMagnification(scalingFactor: scalingFactor)
                                }
                            }) {
                                Image("magnify_minus")  // Assumes that you have an image named 'magnify_minus'
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .padding()
                                    .background(Color.gray.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }


                            .padding(.trailing)
                            .foregroundColor(.white) */
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
                                destination: FolderListView(selectedHold: $selectedHold, selectedHolds: $selectedHolds).navigationBarBackButtonHidden(true),
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
                            if let image = selectedWallImage {
                                let imageCenter = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
                                origin = imageCenter
                            }
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
