//
//  Move.swift
//  TresEnRaya
//
//  Created by Edgar Guitian Rey on 11/4/25.
//

struct Move {
    let player: Player
    let boardIndex: Int

    var indicator: String {
        return player == .human ? "xmark" : "circle"
    }
}
