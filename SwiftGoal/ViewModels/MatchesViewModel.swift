//
//  MatchesViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa

class MatchesViewModel {

    // Inputs
    let active = MutableProperty(false)
    let refreshSink: Observer<Void, NoError>

    // Outputs
    let title: String
    let contentChangesSignal: Signal<Changeset, NoError>
    let isLoading: MutableProperty<Bool>
    let alertMessageSignal: Signal<String, NoError>

    // Actions
    lazy var deleteAction: Action<NSIndexPath, Bool, NSError> = { [unowned self] in
        return Action({ indexPath in
            let match = self.matchAtIndexPath(indexPath)
            return self.store.deleteMatch(match)
        })
    }()

    private let store: Store
    private let contentChangesSink: Observer<Changeset, NoError>
    private let alertMessageSink: Observer<String, NoError>
    private var matches: [Match]

    // MARK: - Lifecycle

    init(store: Store) {
        self.title = "Matches"
        self.store = store
        self.matches = []

        let (refreshSignal, refreshSink) = SignalProducer<Void, NoError>.buffer()
        self.refreshSink = refreshSink

        let (contentChangesSignal, contentChangesSink) = Signal<Changeset, NoError>.pipe()
        self.contentChangesSignal = contentChangesSignal
        self.contentChangesSink = contentChangesSink

        let isLoading = MutableProperty(false)
        self.isLoading = isLoading

        let (alertMessageSignal, alertMessageSink) = Signal<String, NoError>.pipe()
        self.alertMessageSignal = alertMessageSignal
        self.alertMessageSink = alertMessageSink

        // Trigger refresh when view becomes active
        active.producer
            .filter { $0 }
            .map { _ in () }
            .start(refreshSink)

        // Trigger refresh after deleting a match
        deleteAction.values
            .filter { $0 }
            .map { _ in () }
            .observe(refreshSink)

        refreshSignal
            .on(next: { _ in isLoading.value = true })
            .flatMap(.Latest) { _ in
                return store.fetchMatches()
                    .flatMapError { error in
                        alertMessageSink.sendNext(error.localizedDescription)
                        return SignalProducer(value: [])
                    }
            }
            .on(next: { _ in isLoading.value = false })
            .combinePrevious([]) // Preserve history to calculate changeset
            .startWithNext({ [weak self] (oldMatches, newMatches) in
                self?.matches = newMatches
                if let sink = self?.contentChangesSink {
                    let changeset = Changeset(oldItems: oldMatches, newItems: newMatches)
                    sink.sendNext(changeset)
                }
            })

        // Feed deletion errors into alert message signal
        deleteAction.errors
            .map { $0.localizedDescription }
            .observe(alertMessageSink)
    }

    // MARK: - Data Source

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfMatchesInSection(section: Int) -> Int {
        return matches.count
    }

    func homePlayersAtIndexPath(indexPath: NSIndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return separatedNamesForPlayers(match.homePlayers)
    }

    func awayPlayersAtIndexPath(indexPath: NSIndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return separatedNamesForPlayers(match.awayPlayers)
    }

    func resultAtIndexPath(indexPath: NSIndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return "\(match.homeGoals) : \(match.awayGoals)"
    }

    // MARK: View Models

    func editViewModelForNewMatch() -> EditMatchViewModel {
        return EditMatchViewModel(store: store)
    }

    func editViewModelForMatchAtIndexPath(indexPath: NSIndexPath) -> EditMatchViewModel {
        let match = matchAtIndexPath(indexPath)
        return EditMatchViewModel(store: store, match: match)
    }

    // MARK: Internal Helpers

    private func matchAtIndexPath(indexPath: NSIndexPath) -> Match {
        return matches[indexPath.row]
    }

    private func separatedNamesForPlayers(players: [Player]) -> String {
        let playerNames = players.map { player in player.name }
        return playerNames.joinWithSeparator(", ")
    }
}
