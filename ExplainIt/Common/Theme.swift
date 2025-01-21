//
//  Theme.swift
//  ExplainIt
//
//  Created by Olti Maloku on 2025-01-15.
//

// Theme.swift
import SwiftUI

enum Theme {
    // Colors
    //static let accentColor = Color(UIColor(red: 1.0, green: 87/255, blue: 87/255, alpha: 1))
    static let accentColor = Color(UIColor(red: 0.0, green: 0/255, blue: 0/255, alpha: 1))
    //static let accentColor = Color(UIColor(red: 130/255, green: 210/255, blue: 210/255, alpha: 1))
    
    // Fonts
    enum Fonts {
        static func georgia(size: CGFloat) -> Font {
            .custom("Georgia", size: size)
        }
        
        static let title = georgia(size: 40)
        static let heading = georgia(size: 24)
        static let body = georgia(size: 16)
        static let small = georgia(size: 14)
    }
}

// Text Style Extension
extension Text {
    func primaryTitle() -> some View {
        self
            .font(Theme.Fonts.title)
            .fontWeight(.bold)
    }
    
    func heading() -> some View {
        self
            .font(Theme.Fonts.heading)
            .fontWeight(.bold)
    }
    
    func bodyText() -> some View {
        self
            .font(Theme.Fonts.body)
    }
}

// Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.body)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension Button {
    func primaryStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
}
