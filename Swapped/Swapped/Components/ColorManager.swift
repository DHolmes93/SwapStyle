//
//  ColorManager.swift
//  Just Swap
//
//  Created by Donovan Holmes on 11/18/24.
//

import SwiftUI

struct AppTheme {
    let mainColor: Color
    let secondColor: Color
    let thirdColor: Color
    let backgroundColor: Color
    let textColor: Color
    
    static let light = AppTheme(
        mainColor: Color("mainColor"),
        secondColor: Color("secondColor"),
        thirdColor: Color("thirdColor"),
        backgroundColor: Color.white,
        textColor: Color.black
    )
    
    static let dark = AppTheme(
        mainColor: Color("mainColorDark"),
        secondColor: Color("secondColorDark"),
        thirdColor: Color("thirdColorDark"),
        backgroundColor: Color.black,
        textColor: Color.white
    )
}

final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme = .light
    
    func toggleTheme(isDarkMode: Bool) {
        theme = isDarkMode ? .dark : .light
    }
}
