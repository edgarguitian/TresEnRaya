//
//  GameViewModel.swift
//  TresEnRaya
//
//  Created by Edgar Guitian Rey on 11/4/25.
//

import Foundation
import SwiftUI

final class GameViewModel: ObservableObject {
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    @Published var moves: [Move?] = Array(repeating: nil, count: 9)
    @Published var isGameboardDisabled = false
    @Published var alertItem: AlertItem?
    @Published var humanHardWinsCount: Int {
        didSet {
            UserDefaults.standard.set(humanHardWinsCount, forKey: "humanWinsCount")
        }
    }
    @Published var humanUltraHardWinsCount: Int {
        didSet {
            UserDefaults.standard.set(humanUltraHardWinsCount, forKey: "humanUltraWinsCount")
        }
    }

    private let winPatterns: Set<Set<Int>> = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    init() {
        self.humanHardWinsCount = UserDefaults.standard.integer(
            forKey: "humanWinsCount")
        self.humanUltraHardWinsCount = UserDefaults.standard.integer(
            forKey: "humanUltraWinsCount")
    }

    func processPlayerMove(for position: Int, difficulty: GameDifficulty) {
        // Ignore the move if the square is already occupied
        if isSquareOccupied(in: moves, forIndex: position) { return }

        // Register the human move
        moves[position] = Move(player: .human, boardIndex: position)

        // Check if the human wins
        if checkWinCondition(for: .human, in: moves) {
            alertItem = AlertContext.humanWin
            if difficulty == .hard {
                humanHardWinsCount += 1  // Increment win count
            }
            if difficulty == .ultraHard {
                humanUltraHardWinsCount += 1  // Increment win count
            }
            return
        }

        // Check for draw
        if checkForDraw(in: moves) {
            alertItem = AlertContext.draw
            return
        }

        // Disable the gameboard while the computer "thinks"
        isGameboardDisabled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in

            // Decide the computer's move
            let computerPosition: Int
            switch difficulty {
            case .hard:
                computerPosition = determineHardComputerMovePosition(in: moves)
            case .ultraHard:
                computerPosition = determineUltraHardComputerMovePosition(
                    in: moves)
            default:
                computerPosition = determinateSimpleComputerMovePosition(
                    in: moves)
            }

            // Register the computer move
            moves[computerPosition] = Move(
                player: .computer, boardIndex: computerPosition)
            isGameboardDisabled = false

            // Check if the computer wins
            if checkWinCondition(for: .computer, in: moves) {
                alertItem = AlertContext.computerWin
                return
            }

            // Check for draw again
            if checkForDraw(in: moves) {
                alertItem = AlertContext.draw
                return
            }
        }
    }

    func isGameRunning() -> Bool {
        return moves.compactMap { $0 }.count > 0
    }

    func isSquareOccupied(in moves: [Move?], forIndex index: Int) -> Bool {
        return moves.contains(where: { $0?.boardIndex == index })
    }

    func determinateSimpleComputerMovePosition(in moves: [Move?]) -> Int {
        var movePosition = Int.random(in: 0..<9)

        while isSquareOccupied(in: moves, forIndex: movePosition) {
            movePosition = Int.random(in: 0..<9)
        }

        return movePosition
    }

    func determineHardComputerMovePosition(in moves: [Move?]) -> Int {

        // IF AI can win, then win
        if let winMove = winningMove(for: .computer) {
            return winMove
        }

        // IF AI can't win, then block
        if let blockMove = winningMove(for: .human) {
            return blockMove
        }

        // If AI can't block, then take middle square
        if let centerSquare = blockCenterSquare(in: moves) {
            return centerSquare
        }
        
        // IF AI can't take middle square, take random available square
        return determinateSimpleComputerMovePosition(in: moves)

    }
    
    func determineUltraHardComputerMovePosition(in moves: [Move?]) -> Int {
        let availableMoves = (0..<9).filter { !isSquareOccupied(in: moves, forIndex: $0) }

        var bestMove: Int?
        var bestScore = Int.min
        
        // Loop through all available moves and evaluate each one using minimax
        for move in availableMoves {
            // Create a copy of the current state of the gameboard (moves)
            var simulatedMoves = moves
            
            // Simulate the move for the computer
            simulatedMoves[move] = Move(player: .computer, boardIndex: move)
            
            // Evaluate the board after the move using minimax
            let score = minimax(moves: simulatedMoves, depth: 0, isMaximizingPlayer: false)
            
            // If the score is better than the best score, update the best move
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        // Return the best move found
        return bestMove ?? determinateSimpleComputerMovePosition(in: moves)
    }

    // Minimax algorithm to evaluate the best move
    func minimax(moves: [Move?], depth: Int, isMaximizingPlayer: Bool) -> Int {
        // Check if the game is over and return the score
        if checkWinCondition(for: .computer, in: moves) {
            return 10 - depth
        }
        if checkWinCondition(for: .human, in: moves) {
            return depth - 10
        }
        if checkForDraw(in: moves) {
            return 0
        }

        // If it's the maximizing player's turn (computer), try to maximize the score
        if isMaximizingPlayer {
            var bestScore = Int.min
            for move in (0..<9).filter({ !isSquareOccupied(in: moves, forIndex: $0) }) {
                var simulatedMoves = moves
                simulatedMoves[move] = Move(player: .computer, boardIndex: move)
                let score = minimax(moves: simulatedMoves, depth: depth + 1, isMaximizingPlayer: false)
                bestScore = max(bestScore, score)
            }
            return bestScore
        } else {
            // If it's the minimizing player's turn (human), try to minimize the score
            var bestScore = Int.max
            for move in (0..<9).filter({ !isSquareOccupied(in: moves, forIndex: $0) }) {
                var simulatedMoves = moves
                simulatedMoves[move] = Move(player: .human, boardIndex: move)
                let score = minimax(moves: simulatedMoves, depth: depth + 1, isMaximizingPlayer: true)
                bestScore = min(bestScore, score)
            }
            return bestScore
        }
    }

//    func determineUltraHardComputerMovePosition(in moves: [Move?]) -> Int {
//        // First, check if the computer can win on the next move
//        if let winningMove = winningMove(for: .computer) {
//            return winningMove
//        }
//
//        // If the human player can win on the next move, block it
//        if let blockingMove = winningMove(for: .human) {
//            return blockingMove
//        }
//
//        // Then, evaluate if there is a more advanced strategy than just taking the center square
//        // Check if the computer can create a "double threat"
//        if let doubleThreatMove = findDoubleThreatMove(for: .computer) {
//            return doubleThreatMove
//        }
//
//        // If the computer can't create a "double threat", check if it can block the human's "double threat"
//        if let blockDoubleThreat = findDoubleThreatMove(for: .human) {
//            return blockDoubleThreat
//        }
//
//        // If there are no "double threats", check if the center square is available
//        if let centerSquare = blockCenterSquare(in: moves) {
//            return centerSquare
//        }
//
//        // If the center square is taken, take a corner square
//        let corners = [0, 2, 6, 8]
//        for corner in corners {
//            if !isSquareOccupied(in: moves, forIndex: corner) {
//                return corner
//            }
//        }
//
//        // If no strategic moves are available, make a random move on any free square
//        return determinateSimpleComputerMovePosition(in: moves)
//    }

    func checkWinCondition(for player: Player, in moves: [Move?]) -> Bool {

        let playerMoves = moves.compactMap { $0 }.filter { $0.player == player }
        let playerPositions = Set(playerMoves.map { $0.boardIndex })

        for pattern in winPatterns where pattern.isSubset(of: playerPositions) {
            return true
        }

        return false
    }

    func checkForDraw(in moves: [Move?]) -> Bool {
        return moves.compactMap { $0 }.count == 9
    }

    func resetGame() {
        moves = Array(repeating: nil, count: 9)
    }

    private func winningMove(for player: Player) -> Int? {
        let playerPositions = positions(for: player)

        for pattern in winPatterns {
            let winPositions = pattern.subtracting(playerPositions)
            if winPositions.count == 1,
                let index = winPositions.first,
                !isSquareOccupied(in: moves, forIndex: index)
            {
                return index
            }
        }
        return nil
    }

    private func blockCenterSquare(in moves: [Move?]) -> Int? {
        let centerSquare = 4
        if !isSquareOccupied(in: moves, forIndex: centerSquare) {
            return centerSquare
        }
        return nil
    }

    func findDoubleThreatMove(for player: Player) -> Int? {
        let playerPositions = positions(for: player)

        // Check the possible combinations that can create a double threat
        for pattern in winPatterns {
            let availablePositions = pattern.subtracting(playerPositions)

            // If the combination has only two free squares, we can create a double threat
            if availablePositions.count == 2 {
                let availableIndex = availablePositions.first!
                // If the square is not occupied, this is a double threat move
                if !isSquareOccupied(in: moves, forIndex: availableIndex) {
                    return availableIndex
                }
            }
        }
        return nil
    }

    private func positions(for player: Player) -> Set<Int> {
        Set(
            moves.compactMap { $0 }.filter { $0.player == player }.map {
                $0.boardIndex
            })
    }
}
