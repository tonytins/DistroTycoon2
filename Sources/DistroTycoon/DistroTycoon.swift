// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

// TermKit Tutorial
// https://migueldeicaza.github.io/TermKit/documentation/termkit
import TermKit

// var budget = 20000

@main
struct DistroTycoon {
    static func nameDistro(window: Window) {
        let nameLabel = Label("Distro name:")
        nameLabel.x = Pos.at(2)
        nameLabel.y = Pos.at(1)
        nameLabel.width = Dim.sized(20)
        window.addSubview(nameLabel)

        let nameField = TextField("")
        nameField.x = Pos.at(2)
        nameField.y = Pos.at(2)
        nameField.width = Dim.sized(30)
        window.addSubview(nameField)

        let submitButton = Button("Submit")
        submitButton.x = Pos.at(2)
        submitButton.y = Pos.at(4)

        submitButton.clicked = { _ in
            if !nameField.text.isEmpty {
                MessageBox.info("Success!", message: "")
            }
        }

        window.addSubview(submitButton)

        let quitButton = Button("Quit")
        quitButton.x = Pos.at(2)
        quitButton.y = Pos.at(6)
        quitButton.clicked = { _ in
            Application.requestStop()
        }

        window.addSubview(quitButton)
    }

    static func main() {
        Application.prepare()

        let desktop = StandardDesktop()
        let customMenu = MenuBar(menus: [
            MenuBarItem(title: "_File", children: [
                MenuItem(title: "_Quit", action: {
                    Application.requestStop()
                }),
            ]),
        ])
        desktop.addSubview(customMenu)

        let win = Window("Distro Tycoon")
        win.fill()

        nameDistro(window: win)

        Application.top.addSubview(win)
        Application.run()
    }
}
