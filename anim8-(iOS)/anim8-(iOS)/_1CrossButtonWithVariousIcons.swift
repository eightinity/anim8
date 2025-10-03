//
//  _3CrossButtonWithVariousIcons.swift
//  Eightinity Animations
//
//  Created by Gunjan Haider on 26/09/25.
//

import SwiftUI

struct _1CrossButtonWithVariousIcons: View {
    
    @State var animate: Bool = false
    @State var opacity: Bool = true
    @State var size: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                
                ZStack {
                    
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: size, height: size)
                        .opacity(opacity ? 1 : 0)
                    
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .rotationEffect(animate ? .degrees(0) : .degrees(45))
                        .padding()
                        .background(.blue.gradient, in: .circle)
                        .onTapGesture {
                            withAnimation(.spring) {
                                animate.toggle()
                                size = 150
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    opacity = false
                                    size = 0
                                    opacity = true
                                }
                            }
                        }
                }
            
            HStack(spacing: 14) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 1)
                    .animation(.spring(.bouncy(extraBounce: 0.1)).delay(0.01), value: animate)
                    
                
                Image(systemName: "cloud")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 1)
                    .animation(.spring(.bouncy(extraBounce: 0.1)).delay(0.1), value: animate)
                    
                
                Image(systemName: "message")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 1)
                    .animation(.spring(.bouncy(extraBounce: 0.1)).delay(0.15), value: animate)
                    
                
                Image(systemName: "camera")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 1)
                    .animation(.spring(.bouncy(extraBounce: 0.1)).delay(0.2), value: animate)
                    
            }
            .padding()
            .clipped()
            .background(.white, in: .capsule)
            .frame(width: 200, height: 50)
            .offset(y: animate ? -70 : -10)
            .opacity(animate ? 1 : 0)
            .animation(.easeInOut(duration: 0.55), value: animate)
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                animate = false
            }
        }
        .scaleEffect(1.5)
    }
}

#Preview {
    _1CrossButtonWithVariousIcons()
}
