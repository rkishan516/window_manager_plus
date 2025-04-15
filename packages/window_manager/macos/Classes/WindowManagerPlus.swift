import Cocoa
import FlutterMacOS

extension NSWindow {
    private struct AssociatedKeys {
        static var configured: Bool = false
    }
    var configured: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.configured) as? Bool ?? false
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociatedKeys.configured, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    public func hiddenWindowAtLaunch() {
        if (!configured) {
            setIsVisible(false)
            configured = true
        }
    }
    
    public func setStyleMask(_ on: Bool, _ flag: StyleMask) {
        if (on) {
            styleMask.insert(flag)
        } else {
            styleMask.remove(flag)
        }
    }
    
    public func setCollectionBehavior(_ on: Bool, _ flag: CollectionBehavior) {
        if (on) {
            collectionBehavior.insert(flag)
        } else {
            collectionBehavior.remove(flag)
        }
    }
}

extension NSRect {
    var topLeft: CGPoint {
        set {
            let screenFrameRect = NSScreen.screens[0].frame
            origin.x = newValue.x
            origin.y = screenFrameRect.height - newValue.y - size.height
        }
        get {
            let screenFrameRect = NSScreen.screens[0].frame
            return CGPoint(x: origin.x, y: screenFrameRect.height - origin.y - size.height)
        }
    }
}

/// Add extra hooks for window
public class WindowManagerPlusFlutterWindow: NSPanel {
    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }
    
    deinit {
        debugPrint("WindowManagerPlusFlutterWindow dealloc")
    }
}

public class WindowManagerPlus: NSObject, NSWindowDelegate {
    private static var autoincrementId: Int64 = 0;
    private static var windows: [Int64:WindowManagerPlusFlutterWindow?] = [:];
    public static var windowManagers: [Int64:WindowManagerPlus?] = [:];
    
    public var staticChannel: FlutterMethodChannel?
    public var channel: FlutterMethodChannel?
    
    public var id: Int64 = -1;
    
    public static func createWindow(args: [String]) -> Int64 {
        if let RegisterGeneratedPlugins = WindowManagerPlusPlugin.RegisterGeneratedPlugins {
            autoincrementId += 1
            let windowId = autoincrementId
            
            let project = FlutterDartProject()
            var commandLineArguments = [String(windowId)]
            commandLineArguments.append(contentsOf: args)
            project.dartEntrypointArguments = commandLineArguments
            
            let window = WindowManagerPlusFlutterWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 270),
                styleMask: [.miniaturizable, .closable, .resizable, .titled, .fullSizeContentView],
                backing: .buffered, defer: false)
            
            let flutterViewController = FlutterViewController(project: project)
            window.contentViewController = flutterViewController
            
            RegisterGeneratedPlugins(flutterViewController)
            
            WindowManagerPlus.windows[windowId] = window
            
            window.makeKeyAndOrderFront(nil)
            
            return windowId
        }
        return -1
    }
    
    private var _mainWindow: NSWindow?
    public var mainWindow: NSWindow {
        get {
            return _mainWindow!
        }
        set {
            _mainWindow = newValue
            _mainWindow?.delegate = self
        }
    }
    
    private var _isPreventClose: Bool = false
    private var _isMaximized: Bool = false
    private var _isMaximizable: Bool = true
    
    override public init() {
        super.init()
    }
    
    public func waitUntilReadyToShow() {
        // nothing
    }
    
    public func setAsFrameless() {
        mainWindow.styleMask.insert(.fullSizeContentView)
        mainWindow.titleVisibility = .hidden
        mainWindow.isOpaque = true
        mainWindow.hasShadow = false
        mainWindow.backgroundColor = NSColor.clear
        
        if (mainWindow.styleMask.contains(.titled)) {
            let titleBarView: NSView = (mainWindow.standardWindowButton(.closeButton)?.superview)!.superview!
            titleBarView.isHidden = true
        }
    }
    
    public func destroy() {
        NSApp.terminate(nil)
    }
    
    public func close() {
        mainWindow.performClose(nil)
    }
    
    public func isPreventClose() -> Bool {
        return _isPreventClose;
    }
    
    public func setPreventClose(_ args: [String: Any]) {
        _isPreventClose = args["isPreventClose"] as! Bool
    }
    
    public func isMaximizable() -> Bool {
        return _isMaximizable;
    }
    
    public func setIsMaximizable(_ args: [String: Any]) {
        _isMaximizable = args["isMaximizable"] as! Bool
    }
    
    public func focus() {
        NSApp.activate(ignoringOtherApps: false)
        mainWindow.makeKeyAndOrderFront(nil)
    }
    
    public func blur() {
        mainWindow.orderBack(nil)
    }
    
    public func isFocused() -> Bool {
        return mainWindow.isKeyWindow
    }
    
    public func show() {
        mainWindow.setIsVisible(true)
        DispatchQueue.main.async {
            self.mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    public func hide() {
        DispatchQueue.main.async {
            self.mainWindow.orderOut(nil)
        }
    }
    
    public func isVisible() -> Bool {
        return mainWindow.isVisible
    }
    
    public func isMaximized() -> Bool {
        return mainWindow.isZoomed
    }
    
    public func maximize() {
        if (!isMaximized()) {
            mainWindow.zoom(nil);
        }
    }
    
    public func unmaximize() {
        if (isMaximized()) {
            mainWindow.zoom(nil);
        }
    }
    
    public func isMinimized() -> Bool {
        return mainWindow.isMiniaturized
    }
    
    public func minimize() {
        mainWindow.miniaturize(nil)
    }
    
    public func restore() {
        mainWindow.deminiaturize(nil)
    }

    public func isDockable() -> Bool {
        return false
    }

    public func isDocked() -> Int {
        return 0;
    }
    
    public func dock(_ args: [String: Any]) {
        if (isDockable()) {}
    }
    
    public func undock() {
        if (isDockable()) {}
    }
    
    public func isFullScreen() -> Bool {
        return mainWindow.styleMask.contains(.fullScreen)
    }
    
    public func setFullScreen(_ args: [String: Any]) {
        let isFullScreen: Bool = args["isFullScreen"] as! Bool
        
        if (isFullScreen) {
            if (!mainWindow.styleMask.contains(.fullScreen)) {
                mainWindow.toggleFullScreen(nil)
            }
        } else {
            if (mainWindow.styleMask.contains(.fullScreen)) {
                mainWindow.toggleFullScreen(nil)
            }
        }
    }
    
    public func setAspectRatio(_ args: [String: Any]) {
        let hasFrame = !mainWindow.styleMask.contains(.fullSizeContentView);
        let aspectRatio = (args["aspectRatio"] as! NSNumber).doubleValue
        
        // Reset the behaviour to default if aspect_ratio is set to 0 or less.
        if (aspectRatio > 0.0) {
            let aspectRatioSize: NSSize = NSMakeSize(CGFloat(aspectRatio), 1.0)
            if (hasFrame) {
                mainWindow.contentAspectRatio = aspectRatioSize
            } else {
                mainWindow.aspectRatio = aspectRatioSize;
            }
        } else {
            mainWindow.resizeIncrements = NSMakeSize(1.0, 1.0)
        }
    }
    
    public func setBackgroundColor(_ args: [String: Any]) {
        let backgroundColorA = args["backgroundColorA"] as! Int
        let backgroundColorR = args["backgroundColorR"] as! Int
        let backgroundColorG = args["backgroundColorG"] as! Int
        let backgroundColorB = args["backgroundColorB"] as! Int
        
        let isTransparent: Bool = backgroundColorA == 0
        && backgroundColorR == 0
        && backgroundColorG == 0
        && backgroundColorB == 0;
        
        if (isTransparent) {
            mainWindow.backgroundColor = NSColor.clear
        } else {
            let rgbR = CGFloat(backgroundColorR) / 255
            let rgbG = CGFloat(backgroundColorG) / 255
            let rgbB = CGFloat(backgroundColorB) / 255
            let rgbA = CGFloat(backgroundColorA) / 255
            
            mainWindow.backgroundColor = NSColor(red: rgbR,
                                                 green: rgbG,
                                                 blue: rgbB,
                                                 alpha: rgbA)
        }
    }
    
    public func getBounds() -> NSDictionary {
        let frameRect: NSRect = mainWindow.frame;
        
        let data: NSDictionary = [
            "x": frameRect.topLeft.x,
            "y": frameRect.topLeft.y,
            "width": frameRect.size.width,
            "height": frameRect.size.height,
        ]
        return data;
    }
    
    public func setBounds(_ args: [String: Any]) {
        let animate = args["animate"] as? Bool ?? false
        
        var frameRect = mainWindow.frame
        if (args["width"] != nil && args["height"] != nil) {
            let width: CGFloat = CGFloat(truncating: args["width"] as! NSNumber)
            let height: CGFloat = CGFloat(truncating: args["height"] as! NSNumber)
            
            frameRect.origin.y += (frameRect.size.height - height)
            frameRect.size.width = width
            frameRect.size.height = height
        }
        
        if (args["x"] != nil && args["y"] != nil) {
            frameRect.topLeft.x = CGFloat(truncating: args["x"] as! NSNumber)
            frameRect.topLeft.y = CGFloat(truncating: args["y"] as! NSNumber)
        }
        
        if (animate) {
            mainWindow.animator().setFrame(frameRect, display: true, animate: true)
        } else {
            mainWindow.setFrame(frameRect, display: true)
        }
    }
    
    public func setMinimumSize(_ args: [String: Any]) {
        let minSize: NSSize = NSSize(
            width: CGFloat((args["width"] as! NSNumber).floatValue),
            height: CGFloat((args["height"] as! NSNumber).floatValue)
        )
        mainWindow.minSize = minSize
    }
    
    public func setMaximumSize(_ args: [String: Any]) {
        let maxSize: NSSize = NSSize(
            width: CGFloat((args["width"] as! NSNumber).floatValue),
            height: CGFloat((args["height"] as! NSNumber).floatValue)
        )
        mainWindow.maxSize = maxSize
    }
    
    public func isResizable() -> Bool {
        return mainWindow.styleMask.contains(.resizable)
    }
    
    public func setResizable(_ args: [String: Any]) {
        let isResizable: Bool = args["isResizable"] as! Bool
        if (isResizable) {
            mainWindow.styleMask.insert(.resizable)
        } else {
            mainWindow.styleMask.remove(.resizable)
        }
    }
    
    public func isMovable() -> Bool {
        return mainWindow.isMovable
    }
    
    public func setMovable(_ args: [String: Any]) {
        let isMovable: Bool = args["isMovable"] as! Bool
        mainWindow.isMovable = isMovable
    }
    
    public func isMinimizable() -> Bool {
        return mainWindow.styleMask.contains(.miniaturizable)
    }
    
    public func setMinimizable(_ args: [String: Any]) {
        let isMinimizable: Bool = args["isMinimizable"] as! Bool
        if (isMinimizable) {
            mainWindow.styleMask.insert(.miniaturizable)
        } else {
            mainWindow.styleMask.remove(.miniaturizable)
        }
    }
    
    public func isClosable() -> Bool {
        return mainWindow.styleMask.contains(.closable)
    }
    
    public func setClosable(_ args: [String: Any]) {
        let isClosable: Bool = args["isClosable"] as! Bool
        if (isClosable) {
            mainWindow.styleMask.insert(.closable)
        } else {
            mainWindow.styleMask.remove(.closable)
        }
    }
    
    public func isAlwaysOnTop() -> Bool {
        return mainWindow.level == .floating
    }
    
    public func setAlwaysOnTop(_ args: [String: Any]) {
        let isAlwaysOnTop: Bool = args["isAlwaysOnTop"] as! Bool
        mainWindow.level = isAlwaysOnTop ? .floating : .normal
        if (mainWindow is NSPanel) {
            mainWindow.setStyleMask(isAlwaysOnTop, .nonactivatingPanel)
        }
    }
    
    public func getTitle() -> String {
        return mainWindow.title
    }
    
    public func setTitle(_ args: [String: Any]) {
        let title: String = args["title"] as! String
        mainWindow.title = title;
    }
    
    public func setTitleBarStyle(_ args: [String: Any]) {
        let titleBarStyle: String = args["titleBarStyle"] as! String
        let windowButtonVisibility: Bool = args["windowButtonVisibility"] as! Bool
        
        if (titleBarStyle == "hidden") {
            mainWindow.titleVisibility = .hidden
            mainWindow.titlebarAppearsTransparent = true
            mainWindow.styleMask.insert(.fullSizeContentView)
        } else {
            mainWindow.titleVisibility = .visible
            mainWindow.titlebarAppearsTransparent = false
            mainWindow.styleMask.remove(.fullSizeContentView)
        }
        
        mainWindow.isOpaque = false
        mainWindow.hasShadow = true
        
        let titleBarView: NSView = (mainWindow.standardWindowButton(.closeButton)?.superview)!.superview!
        titleBarView.isHidden = false
        
        mainWindow.standardWindowButton(.closeButton)?.isHidden = !windowButtonVisibility
        mainWindow.standardWindowButton(.miniaturizeButton)?.isHidden = !windowButtonVisibility
        mainWindow.standardWindowButton(.zoomButton)?.isHidden = !windowButtonVisibility
    }
    
    public func getTitleBarHeight() -> Int {
        let frame = mainWindow.frame;
        let windowHeight: CGFloat = mainWindow.frame.height
        return Int(windowHeight - mainWindow.contentRect(forFrameRect: frame).height)
    }
    
    public func isSkipTaskbar() -> Bool {
        return NSApplication.shared.activationPolicy() == .accessory
    }
    
    public func setSkipTaskbar(_ args: [String: Any]) {
        let isSkipTaskbar: Bool = args["isSkipTaskbar"] as! Bool
        NSApplication.shared.setActivationPolicy(isSkipTaskbar ? .accessory : .regular)
    }
    
    public func setBadgeLabel(_ args: [String: Any]) {
        let label: String = args["label"] as! String
        NSApplication.shared.dockTile.badgeLabel = label
    }
    
    public func setProgressBar(_ args: [String: Any]) {
        let progress: CGFloat = CGFloat(truncating: args["progress"] as! NSNumber)
        
        let dockTile: NSDockTile = NSApp.dockTile;
        
        let firstTime = dockTile.contentView == nil || dockTile.contentView?.subviews.count == 0
        
        if (firstTime) {
            let imageView: NSImageView = NSImageView.init()
            imageView.image = NSApp.applicationIconImage
            dockTile.contentView = imageView
            
            let frame: NSRect = NSMakeRect(0.0, 0.0, dockTile.size.width, 15.0)
            let progressIndicator: NSProgressIndicator = NSProgressIndicator.init(frame: frame)
            progressIndicator.style = .bar
            progressIndicator.isIndeterminate = false
            progressIndicator.minValue = 0
            progressIndicator.maxValue = 1
            progressIndicator.isHidden = false
            dockTile.contentView?.addSubview(progressIndicator)
        }
        
        let progressIndicator: NSProgressIndicator = dockTile.contentView!.subviews.last as! NSProgressIndicator
        if (progress < 0) {
            progressIndicator.isHidden = true
        } else if (progress > 1) {
            progressIndicator.isHidden = false
            progressIndicator.isIndeterminate = true
            progressIndicator.doubleValue = 1
        } else {
            progressIndicator.isHidden = false
            progressIndicator.doubleValue = Double(progress)
        }
        dockTile.display()
    }
    
    public func isVisibleOnAllWorkspaces() -> Bool {
        return mainWindow.collectionBehavior.contains(.canJoinAllSpaces)
    }
    
    public func setVisibleOnAllWorkspaces(_ args: [String: Any]) {
        let visible: Bool = args["visible"] as! Bool
        let visibleOnFullScreen: Bool = args["visibleOnFullScreen"] as! Bool
        
        mainWindow.setCollectionBehavior(visible, .canJoinAllSpaces)
        mainWindow.setCollectionBehavior(visibleOnFullScreen, .fullScreenAuxiliary)
    }
    
    public func hasShadow() -> Bool {
        return mainWindow.hasShadow
    }
    
    public func setHasShadow(_ args: [String: Any]) {
        let hasShadow: Bool = args["hasShadow"] as! Bool
        mainWindow.hasShadow = hasShadow;
        mainWindow.invalidateShadow();
    }
    
    public func getOpacity() -> CGFloat {
        return mainWindow.alphaValue
    }
    
    public func setOpacity(_ args: [String: Any]) {
        let opacity: CGFloat = CGFloat(truncating: args["opacity"] as! NSNumber)
        mainWindow.alphaValue = opacity
    }
    
    public func setBrightness(_ args: [String: Any]) {
        let brightness: String = args["brightness"] as! String
        if (brightness == "dark") {
            mainWindow.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        } else {
            mainWindow.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        }
        mainWindow.invalidateShadow()
    }
    
    public func setIgnoreMouseEvents(_ args: [String: Any]) {
        let ignore: Bool = args["ignore"] as! Bool
        let forward: Bool = args["forward"] as! Bool
        mainWindow.ignoresMouseEvents = ignore
        
        if (!ignore) {
            mainWindow.acceptsMouseMovedEvents = false
        } else {
            mainWindow.acceptsMouseMovedEvents = forward
        }
    }
    
    public func startDragging() {
        DispatchQueue.main.async {
            let window: NSWindow  = self.mainWindow
            if(window.currentEvent != nil) {
                window.performDrag(with: window.currentEvent!)
            }
        }
    }
    
    // NSWindowDelegate
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        emitEvent("close")
        if (isPreventClose()) {
            return false
        }
        return true;
    }
    
    public func windowWillClose(_ notification: Notification) {
        WindowManagerPlus.windowManagers[id]??.staticChannel?.setMethodCallHandler(nil)
        WindowManagerPlus.windowManagers[id]??.staticChannel = nil
        WindowManagerPlus.windowManagers[id]??.channel?.setMethodCallHandler(nil)
        WindowManagerPlus.windowManagers[id]??.channel = nil
        WindowManagerPlus.windowManagers[id]??._mainWindow?.delegate = nil
        WindowManagerPlus.windowManagers[id]??._mainWindow = nil
        WindowManagerPlus.windowManagers[id] = nil
        WindowManagerPlus.windows[id] = nil
    }
    
    public func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        emitEvent("maximize")
        if (isMaximizable()) {
            return true
        }
        return false;
    }
    
    public func windowDidResize(_ notification: Notification) {
        emitEvent("resize")
        if (!_isMaximized && mainWindow.isZoomed) {
            _isMaximized = true
            emitEvent("maximize")
        }
        if (_isMaximized && !mainWindow.isZoomed) {
            _isMaximized = false
            emitEvent("unmaximize")
        }
    }
    
    public func windowDidEndLiveResize(_ notification: Notification) {
        emitEvent("resized")
    }
    
    public func windowWillMove(_ notification: Notification) {
        emitEvent("move")
    }
    
    public func windowDidMove(_ notification: Notification) {
        emitEvent("moved")
    }
    
    public func windowDidBecomeKey(_ notification: Notification) {
        if (mainWindow is NSPanel) {
            emitEvent("focus");
        }
    }
    
    public func windowDidResignKey(_ notification: Notification) {
        if (mainWindow is NSPanel) {
            emitEvent("blur");
        }
    }
    
    public func windowDidBecomeMain(_ notification: Notification) {
        emitEvent("focus");
    }
    
    public func windowDidResignMain(_ notification: Notification){
        emitEvent("blur");
    }
    
    public func windowDidMiniaturize(_ notification: Notification) {
        emitEvent("minimize");
    }
    
    public func windowDidDeminiaturize(_ notification: Notification) {
        emitEvent("restore");
    }
    
    public func windowDidEnterFullScreen(_ notification: Notification){
        emitEvent("enter-full-screen");
    }
    
    public func windowDidExitFullScreen(_ notification: Notification){
        emitEvent("leave-full-screen");
    }
    
    public func emitEvent(_ eventName: String) {
        let args: NSDictionary = [
            "eventName": eventName,
        ]
        channel?.invokeMethod("onEvent", arguments: args, result: nil)
        
        emitGlobalEvent(eventName)
    }
    
    public func emitGlobalEvent(_ eventName: String) {
        let args: NSDictionary = [
            "eventName": eventName,
            "windowId": id
        ]
        
        let wManagers = WindowManagerPlus.windowManagers;
        wManagers.forEach { (key: Int64, value: WindowManagerPlus?) in
            if let wm = value {
                wm.channel?.invokeMethod("onEvent", arguments: args)
            }
        }
    }
    
    deinit {
        debugPrint("WindowManagerPlus dealloc")
    }
}
