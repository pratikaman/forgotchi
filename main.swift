import AppKit

// Forgotchi: a desktop egg whose 8-bit smith hammers while any Claude Code session is working.
// hook.sh keeps one file per busy session in stateDir; no fresh file = idle = frozen scene.

let stateDir = "/tmp/claude-tama"
let W = 32, H = 24, S: CGFloat = 4 // scene is 32x24 game pixels, 4pt each

func hex(_ v: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(v >> 16 & 255) / 255, green: CGFloat(v >> 8 & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1)
}

// h hair, c bandana, s skin, e eye/boots, u tunic, a apron, b belt, y gold, p pants,
// G/g/d anvil light/mid/dark, m/M hammer head, w handle, f/F floor. Anything else is transparent.
let palette: [Character: NSColor] = [
    "h": hex(0x6b3e1f), "c": hex(0xd03a2a), "s": hex(0xf2b27a), "e": hex(0x1a1012),
    "u": hex(0x4a64a8), "a": hex(0x8a5530), "b": hex(0x2a1a14), "y": hex(0xffd84a),
    "p": hex(0x3a3a5e), "G": hex(0xa8a8bc), "g": hex(0x6e6e84), "d": hex(0x44445a),
    "m": hex(0xc8c8d8), "M": hex(0x7a7a90), "w": hex(0xa8683a), "f": hex(0x5a4638), "F": hex(0x3e2f26),
]

// Smith (minus hammer arm), anvil and floor. The iron on the anvil is drawn in code.
let scene = [
    "................................",
    "................................",
    "................................",
    ".......hhhh.....................",
    "......cccccc....................",
    "......hhssss....................",
    "......hssses....................",
    "......hssssss...................",
    "......hhhhhh....................",
    ".......hhhh.....................",
    ".....uuuuuuu....................",
    "....suuuuuuu....................",
    "....suuaaaaa....................",
    "....suuaaaaa....................",
    "....sbbbbybb....................",
    "....sppaaaaa....................",
    ".....ppaaaaa....GGGGGGGGGGGgggg.",
    ".....pppppp.....gggggggggggdd...",
    ".....pp..pp......ddddddddd......",
    "....pp....pp.......ggggg........",
    "....pp....pp.......ggggg........",
    "..eeee....eee.....ggggggg.......",
    "ffffffffffffffffffffffffffffffff",
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
]

// Hammer arm poses, drawn over the scene at (x, y): 0 rest, 1 raised, 2 swinging, 3 strike.
let poses: [(x: Int, y: Int, rows: [String])] = [
    (12, 11, ["s.....", "ss....", ".ss...", "..ss..", "...w..", "...w..", "...w..", "...w..", ".mmmmm", ".mmmmm", ".MMMMM"]),
    (12, 0, ["mmmmm", "mmmmm", "MMMMM", "..w..", "..w..", ".ss..", ".ss..", ".ss..", ".ss..", "ss...", "s...."]),
    (12, 1, ["........mmm", "........mmm", "........MMM", ".......w...", "......w....", ".....w.....",
             "...ss......", "..ss.......", ".ss........", "ss........."]),
    (12, 10, [".........mmM", "s........mmM", "sssswwwwwmmM", ".sss.....mmM", ".........mmM"]),
]
let swing = [1, 1, 1, 1, 2, 3, 3, 3, 2] // pose per tick at 12 fps; index 5 is the strike
let strikeTick = 5

func claudeWorking() -> Bool {
    let fm = FileManager.default
    guard let names = try? fm.contentsOfDirectory(atPath: stateDir) else { return false }
    // ponytail: a session that crashes mid-turn leaves its file behind, so files expire after 30 min;
    // a single tool call longer than that pauses the smith until the next hook fires.
    return names.contains { name in
        let date = (try? fm.attributesOfItem(atPath: "\(stateDir)/\(name)"))?[.modificationDate] as? Date
        return date.map { -$0.timeIntervalSinceNow < 1800 } ?? false
    }
}

// The shell, in the same 4pt game pixels as the scene, styled after a pixel-art Tamagotchi icon:
// ink outline, lit left / shaded right, highlight arc, two-tone body, keyring on top.
let SW = 58, SH = 64, screenAt = (x: 13, y: 16)
let shellPixels: [NSColor?] = {
    func body(_ x: Int, _ y: Int) -> Bool { // squircle, 56x60
        let nx = (Double(x) + 0.5 - 29) / 28, ny = (Double(y) + 0.5 - 34) / 30
        return pow(abs(nx), 2.4) + pow(abs(ny), 2.4) <= 1
    }
    let ink = hex(0x2b1b2e), cream = hex(0xffe0a8)
    var px = [NSColor?](repeating: nil, count: SW * SH)
    func sprite(_ rows: [String], _ ox: Int, _ oy: Int, _ colors: [Character: NSColor]) {
        for (dy, row) in rows.enumerated() {
            for (dx, ch) in row.enumerated() { if let c = colors[ch] { px[(oy + dy) * SW + ox + dx] = c } }
        }
    }
    sprite(["..kkkk..", ".kmmmmk.", "kmk..kmk", "kmk..kmk", "kmk..kmk"], 25, 0, ["k": ink, "m": hex(0x9a9ab4)])
    for y in 0..<SH {
        for x in 0..<SW where body(x, y) {
            let edge = !body(x - 1, y) || !body(x + 1, y) || !body(x, y - 1) || !body(x, y + 1)
            let nearEdge = !body(x - 2, y) || !body(x + 2, y) || !body(x, y - 2) || !body(x, y + 2)
            let shaded = (Double(x) + 0.5 - 29) / 28 > 0.5
            px[y * SW + x] = edge || y == 45 ? ink
                : nearEdge && x < 26 && y < 24 ? cream
                : y > 45 ? (shaded ? hex(0x8e2a25) : hex(0xb23a2f))
                : (shaded ? hex(0xc9562a) : hex(0xe8743b))
        }
    }
    for y in 14...41 { for x in 11...46 { px[y * SW + x] = ink } } // bezel; the screen covers its middle
    for (bx, by) in [(16, 50), (26, 51), (36, 50)] {
        sprite([".kkkk.", "kcccck", "kcccck", ".kkkk."], bx, by, ["k": ink, "c": cream])
    }
    return px
}()

final class Forge: NSView {
    var working = false, tick = 0, glow: CGFloat = 0
    var sparks: [(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, life: Int)] = []

    override var isFlipped: Bool { true }

    @objc func step() {
        let busy = claudeWorking()
        if busy != working { working = busy; tick = 0; sparks = []; glow = 0; needsDisplay = true }
        guard working else { return } // idle: nothing moves, nothing redraws
        tick += 1
        glow *= 0.7
        sparks = sparks.compactMap { s in
            var s = s
            s.x += s.vx; s.y += s.vy; s.vy += 0.3; s.life -= 1
            return s.life > 0 ? s : nil
        }
        if tick % swing.count == strikeTick {
            glow = 1
            for _ in 0..<10 {
                sparks.append((22, 14, .random(in: -0.8...1.8), .random(in: -2.4 ... -0.6), .random(in: 5...11)))
            }
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        for (i, c) in shellPixels.enumerated() {
            c?.setFill()
            if c != nil { NSRect(x: CGFloat(i % SW) * S, y: CGFloat(i / SW) * S, width: S, height: S).fill() }
        }
        let screen = NSRect(x: CGFloat(screenAt.x) * S, y: CGFloat(screenAt.y) * S, width: CGFloat(W) * S, height: CGFloat(H) * S)
        hex(0x1d1422).setFill()
        screen.fill()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: screen).addClip()
        var o = screen.origin
        if glow == 1 { o.y += S } // one-frame jolt on the strike
        func px(_ x: Int, _ y: Int, _ c: NSColor) {
            c.setFill()
            NSRect(x: o.x + CGFloat(x) * S, y: o.y + CGFloat(y) * S, width: S, height: S).fill()
        }
        func paint(_ rows: [String], _ ox: Int, _ oy: Int) {
            for (dy, row) in rows.enumerated() {
                for (dx, ch) in row.enumerated() { if let c = palette[ch] { px(ox + dx, oy + dy, c) } }
            }
        }

        if working {
            let c = NSPoint(x: o.x + 22 * S, y: o.y + 15 * S)
            NSGradient(starting: hex(0xff7a1a).withAlphaComponent(0.5 * max(glow, 0.35)), ending: .clear)!
                .draw(fromCenter: c, radius: 0, toCenter: c, radius: 70, options: [])
        }
        paint(scene, 0, 0)
        for x in 19...24 { // the iron: glowing while working, cooled to dull red when idle
            let core = (21...22).contains(x)
            px(x, 15, !working ? hex(0x7a2a1e) : core ? (glow == 1 ? hex(0xfffbe6) : hex(0xffd84a)) : hex(0xff8a1c))
        }
        let pose = poses[working ? swing[tick % swing.count] : 0]
        paint(pose.rows, pose.x, pose.y)
        for s in sparks {
            px(Int(s.x), Int(s.y), s.life > 7 ? hex(0xfff6b0) : s.life > 3 ? hex(0xffb02e) : hex(0xd8401c))
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

precondition(scene.count == H && scene.allSatisfy { $0.count == W }, "scene must be \(W)x\(H)")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let size = NSSize(width: CGFloat(SW) * S, height: CGFloat(SH) * S)
let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
let panel = NSPanel(contentRect: NSRect(origin: NSPoint(x: vf.maxX - size.width - 24, y: vf.maxY - size.height - 24), size: size),
                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
panel.level = .floating
panel.backgroundColor = .clear
panel.isOpaque = false
panel.hasShadow = true
panel.hidesOnDeactivate = false
panel.isMovableByWindowBackground = true
panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
let forge = Forge(frame: NSRect(origin: .zero, size: size))
let menu = NSMenu()
menu.addItem(withTitle: "Quit Forgotchi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "").target = app
forge.menu = menu
panel.contentView = forge
panel.setFrameAutosaveName("Forgotchi")
panel.setContentSize(size) // keep the saved position, not a saved size from an older shell
panel.orderFrontRegardless()
Timer.scheduledTimer(timeInterval: 1.0 / 12, target: forge, selector: #selector(Forge.step), userInfo: nil, repeats: true)
app.run()
