//
//  ContentView.swift
//  TresEnRaya
//
//  Created by Edgar Guitian Rey on 11/4/25.
//

import SwiftUI

struct GameView: View {

    @StateObject private var viewModel = GameViewModel()
    @State private var difficulty: GameDifficulty = .normal  // Store selected difficulty

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                if !viewModel.isGameRunning() {
                    VStack {
                        HardDifficultyWinCounter(
                            numHardDifficultyWins: viewModel.humanHardWinsCount)
                        UltraHardDifficultyWinCounter(
                            numUltraHardDifficultyWins: viewModel
                                .humanUltraHardWinsCount)
                    }
                    .padding(.bottom)

                    DifficultySelectorView(selectedDifficulty: $difficulty)
                        .padding(.bottom)
                }

                GameBoardView(
                    proxy: geometry,
                    moves: viewModel.moves,
                    columns: viewModel.columns,
                    onTap: { index in
                        viewModel.processPlayerMove(
                            for: index, difficulty: difficulty)
                    }
                )

                Spacer()
            }

            .disabled(viewModel.isGameboardDisabled)
            .padding()

            .alert(
                item: $viewModel.alertItem,
                content: { alertItem in
                    Alert(
                        title: alertItem.title, message: alertItem.message,
                        dismissButton: .default(
                            alertItem.buttonTitle,
                            action: { viewModel.resetGame() }))
                })
        }
        .background(.gray.opacity(0.2))
        .ignoresSafeArea()
    }
}

struct GameBoardView: View {
    let proxy: GeometryProxy
    let moves: [Move?]
    let columns: [GridItem]
    let onTap: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<9) { index in
                ZStack {
                    GameSquareView(proxy: proxy)
                    PlayerIndicator(
                        systemImageName: moves[index]?.indicator ?? "")
                }
                .onTapGesture {
                    onTap(index)
                }
            }
        }
    }
}

struct GameSquareView: View {

    var proxy: GeometryProxy

    var body: some View {
        Circle()
            .foregroundColor(.red).opacity(0.6)
            .frame(
                width: proxy.size.width / 3 - 15,
                height: proxy.size.width / 3 - 15
            )
            .shadow(radius: 5)
    }
}

struct PlayerIndicator: View {

    var systemImageName: String

    var body: some View {
        Image(systemName: systemImageName)
            .resizable()
            .frame(width: 50, height: 50)
            .foregroundColor(.black)
    }
}

struct DifficultySelectorView: View {
    @Binding var selectedDifficulty: GameDifficulty

    var body: some View {
        VStack {
            Text("Select Difficulty:")
                .font(.headline)
                .padding(.bottom, 5)

            Picker("Difficulty", selection: $selectedDifficulty) {
                Text("Normal").tag(GameDifficulty.normal)
                Text("Hard").tag(GameDifficulty.hard)
                Text("Ultra Hard").tag(GameDifficulty.ultraHard)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .shadow(radius: 5)
        }
        .padding(.bottom, 20)
    }
}

struct HardDifficultyWinCounter: View {
    let numHardDifficultyWins: Int
    var body: some View {
        Text("Hard Difficulty Wins: \(numHardDifficultyWins)")
            .font(.subheadline)
            .bold()
    }
}

struct UltraHardDifficultyWinCounter: View {
    let numUltraHardDifficultyWins: Int
    var body: some View {
        Text("Ultra Hard Difficulty Wins: \(numUltraHardDifficultyWins)")
            .font(.subheadline)
            .bold()
    }
}

#Preview {
    GameView()
}
