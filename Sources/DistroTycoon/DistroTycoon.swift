// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

// TermKit Tutorial
// https://migueldeicaza.github.io/TermKit/documentation/termkit
import TermKit

func makeNewRelease(distro: UserDistro) {
    distro.distroVersion = 1
    // MessageBox.info("Congrats!", message: "\(distro.distroVersion).0 of \(distro.distroName) has been released! Time to sit back and relax")
    showRandomGain()

}

func nameDistro(desktop: StandardDesktop, distro: UserDistro) {
    let win = Window("Create your Distro")
    win.fill(padding: 2)

    desktop.addSubview(win)

    let nameLabel = Label("Distro name:")
    nameLabel.x = Pos.at(2)
    nameLabel.y = Pos.at(1)
    nameLabel.width = Dim.sized(20)
    win.addSubview(nameLabel)

    let nameField = TextField("")
    nameField.x = Pos.at(2)
    nameField.y = Pos.at(2)
    nameField.width = Dim.sized(30)
    win.addSubview(nameField)

    let submitButton = Button("Submit")
    submitButton.x = Pos.at(2)
    submitButton.y = Pos.at(4)

    submitButton.clicked = { _ in
        if !nameField.text.isEmpty {
            distro.nameDistro(name: nameField.text)
            makeNewRelease(distro: distro)
            desktop.removeSubview(win)
        }
    }

    win.addSubview(submitButton)
}

@main
struct DistroTycoon {
    static func main() {
        Application.prepare()

        let distro = UserDistro()
        let desktop = StandardDesktop()
        let customMenu = MenuBar(menus: [
            MenuBarItem(title: "_File", children: [
                MenuItem(title: "_About", action: {
                    MessageBox.info("About", message: "Distro Tycoon 0.1")
                }),
                MenuItem(title: "_Quit", action: {
                    Application.requestStop()
                }),
            ]),
        ])

        desktop.addSubview(customMenu)

        nameDistro(desktop: desktop, distro: distro)

        Application.top.addSubview(desktop)
        Application.run()
    }
}
