//
//  GameDifficulty.swift
//  TresEnRaya
//
//  Created by Edgar Guitian Rey on 11/4/25.
//

enum GameDifficulty: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case hard = "Hard"
    case ultraHard = "Ultra Hard"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .ultraHard: return "Ultra Hard"
        }
    }
}
