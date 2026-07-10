import Cocoa

class SpotifyObserver {
  // Keep a strong reference to windows so they aren't immediately garbage collected
  private var activeWindows: [NSWindow] = []

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
    // 1. Define dimensions
    let windowWidth: CGFloat = 360
    let windowHeight: CGFloat = 90

    // 2. Calculate top-center position dynamically based on current screen
    let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let xPos = screenRect.origin.x + (screenRect.width - windowWidth) / 2
    let yPos = screenRect.origin.y + screenRect.height - windowHeight - 20  // 20px padding from the top menu bar

    // 3. Create the borderless window
    let window = NSWindow(
      contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    window.level = .floating
    window.isOpaque = false
    window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
    window.hasShadow = true

    // Rounded corners for the container view
    let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
    contentView.wantsLayer = true
    contentView.layer?.cornerRadius = 12
    contentView.layer?.masksToBounds = true

    // 4. Setup Image View (Left Side)
    let imageSize: CGFloat = 70
    let imageView = NSImageView(
      frame: NSRect(x: 10, y: (windowHeight - imageSize) / 2, width: imageSize, height: imageSize))
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 6
    imageView.layer?.masksToBounds = true
    contentView.addSubview(imageView)

    // 5. Setup Text Label (Right Side - pushed over by image size + padding)
    let labelX = 10 + imageSize + 12
    let labelWidth = windowWidth - labelX - 15
    let label = NSTextField(labelWithString: "\(track)\n\(artist)")
    label.frame = NSRect(x: labelX, y: (windowHeight - 50) / 2, width: labelWidth, height: 50)
    label.textColor = .white
    label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
    contentView.addSubview(label)

    window.contentView = contentView

    // 6. Asynchronously fetch the album artwork
    if let url = URL(string: artwork) {
      URLSession.shared.dataTask(with: url) { [weak imageView] data, _, _ in
        if let data = data, let image = NSImage(data: data) {
          DispatchQueue.main.async {
            imageView?.image = image
          }
        }
      }
      .resume()
    }

    // 7. Track windows cleanly to present and release memory
    window.makeKeyAndOrderFront(nil)
    self.activeWindows.append(window)

    // 8. Auto-dismiss
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self, weak window] in
      guard let window = window else { return }
      window.close()
      self?.activeWindows.removeAll { $0 == window }
    }
  }
}

let app = NSApplication.shared
let observer = SpotifyObserver()
observer.startListening()
observer.handleTrackChange()
app.run()
