import Cocoa

class SpotifyObserver {
    func startListening() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleTrackChange()
        }
        print("Listening for Spotify events...")
    }

    func handleTrackChange() {
        let scriptStr = """
        tell application "Spotify"
            if player state is playing then
                set tName to name of current track
                set tArtist to artist of current track
                set tArtwork to artwork url of current track
                return tName & "|||" & tArtist & "|||" & tArtwork
            end if
            return ""
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptStr) {
            let output = scriptObject.executeAndReturnError(&error)
            if let resultString = output.stringValue, !resultString.isEmpty {
                let parts = resultString.components(separatedBy: "|||")
                if parts.count == 3 {
                    let track = parts[0]
                    let artist = parts[1]
                    let artworkUrl = parts[2]
                    
                    showPopup(track: track, artist: artist, artwork: artworkUrl)
                }
            }
        }
    }

func showPopup(track: String, artist: String, artwork: String) {
    // 1. Create a borderless window
    let window = NSWindow(
        contentRect: NSRect(x: 20, y: 50, width: 300, height: 100),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
    )
    
    // 2. Make it float above all other apps
    window.level = .floating
    window.isOpaque = false
    window.backgroundColor = NSColor.black.withAlphaComponent(0.8)
    
    // 3. Create a simple label (View)
    let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
    let label = NSTextField(labelWithString: "\(track)\n\(artist)")
    label.frame = NSRect(x: 20, y: 20, width: 260, height: 60)
    label.textColor = .white
    
    contentView.addSubview(label)
    window.contentView = contentView
    
    // 4. Show it
    window.makeKeyAndOrderFront(nil)
    
    // 5. Hide it automatically after 5 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        window.close()
    }
}

}

let app = NSApplication.shared
let observer = SpotifyObserver()
observer.startListening()
observer.handleTrackChange()
app.run()
