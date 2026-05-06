import TermKit
import Foundation

class Gameplay {
    var timeUpdate: Int = 0
    var timeRank: Int = 0
    var gameSpeed: Int = 0
    var week: Int = 0
    var year: Int = 0

    func gameTime(date: Date)
    {
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: date)
        let min = calendar.component(.minute, from: date)
        let sec = calendar.component(.second, from: date)

        var cycle = (hour % 2 == 1) ? 3600 : 0
        cycle += min * 60 + sec
    }
}

class UserDistro {
    var distroName: String = ""
    var hype: Int = 0
    var distroVersion: Int = 0
    var users: Int = 0

    func nameDistro(name: String) {
        distroName = name
    }

    func updateHype(hype: Int) {
        self.hype += hype
    }
}

func chanceCard(distro: UserDistro) {
    let chance = Int.random(in: 1 ..< 35)

    if chance == 20 {
        MessageBox.info("", message: "Your latest version got reviewed favorably in a major magazine!")
        distro.hype += 5
    }
}
