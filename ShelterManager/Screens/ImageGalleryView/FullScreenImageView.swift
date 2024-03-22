//
//  FullScreenImageView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 11.03.2024.
//

import Foundation
import SwiftUI
import Kingfisher
import AlertToast

public struct FullScreenImageView: View {

    var image: Image? = nil
    var url: URL? = nil
    @Environment(\.dismiss) var dismiss

    @State var resultImage: UIImage?
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero
    
    @State private var okAlert: Bool = false

    public init(image: Image) {
        self.image = image
    }
    
    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    if let image = image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: offset.x, y: offset.y)
                            .gesture(makeDragGesture(size: proxy.size))
                            .gesture(makeMagnificationGesture(size: proxy.size))
                    }
                    if let url = url {
                        KFImage(url)
                            .onSuccess({ img in
                                if let cgimg = img.image.cgImage {
                                    self.resultImage = UIImage(cgImage: cgimg)
                                }
                            })
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: offset.x, y: offset.y)
                            .gesture(makeDragGesture(size: proxy.size))
                            .gesture(makeMagnificationGesture(size: proxy.size))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .toast(isPresenting: $okAlert) {
                    AlertToast(displayMode: .alert, type: .complete(.green))
                }
            }.navigationTitle("image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    
                    Button {
                       dismiss()
                    } label: {
                        Label {
                            Text("close")
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                        }

                    }
                    
                    Button {
                        guard let image = resultImage else { return }
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        okAlert.toggle()
                    } label: {
                        Label {
                            Text("save")
                        } icon: {
                            Image(systemName: "square.and.arrow.down.fill")
                        }

                    }

                }
        }
    }
    
    private func convert(image: Image, callback: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.async {
            let renderer = ImageRenderer(content: image)
            callback(renderer.uiImage)
        }
    }
    
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }

    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}
