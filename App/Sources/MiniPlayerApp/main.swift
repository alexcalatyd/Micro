import AppKit

setvbuf(stdout, nil, _IONBF, 0) // sin buffer, para ver los prints de debug al instante

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
