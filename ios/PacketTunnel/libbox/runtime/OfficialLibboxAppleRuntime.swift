import Foundation
import NetworkExtension
#if canImport(Libbox)
import Libbox
import Network
import UserNotifications
#endif

final class OfficialLibboxAppleRuntime: NSObject, IOSSingBoxRuntime {
  private let context: ObjCSingBoxLaunchContext
  #if canImport(Libbox)
  private var controller: ProjectIOSLibboxController?
  #endif

  init(context: ObjCSingBoxLaunchContext) {
    self.context = context
    super.init()
  }

  func start() throws {
    #if canImport(Libbox)
    let controller = ProjectIOSLibboxController(context: context)
    try controller.start()
    self.controller = controller
    #else
    throw NSError(
      domain: "inet.vpn",
      code: -41,
      userInfo: [NSLocalizedDescriptionKey: buildActionableMessage()]
    )
    #endif
  }

  func stop() {
    #if canImport(Libbox)
    controller?.stop()
    controller = nil
    #endif
  }

  private func buildActionableMessage() -> String {
    let frameworkPath = Bundle.main.privateFrameworksPath ?? "<PacketTunnel target>/Frameworks"
    return [
      "Libbox.xcframework is not linked into the PacketTunnel target yet.",
      "Place Libbox.xcframework under ios/Frameworks/ (or your host iOS project Frameworks directory).",
      "Add it to the PacketTunnel extension target, not only the main Runner target.",
      "If you have the uploaded sing-box sources on macOS, run ./tools/build_libbox_apple_from_uploaded_sources.sh first.",
      "Then rebuild the iOS app on macOS/Xcode so #if canImport(Libbox) becomes active.",
      "Expected search path: \(frameworkPath)",
    ].joined(separator: " ")
  }
}

#if canImport(Libbox)
private final class ProjectIOSLibboxController {
  private let context: ObjCSingBoxLaunchContext
  private var commandServer: LibboxCommandServer?
  private var platformInterface: ProjectIOSPlatformInterface?

  init(context: ObjCSingBoxLaunchContext) {
    self.context = context
  }

  func start() throws {
    try FileManager.default.createDirectory(at: context.workingDirectory, withIntermediateDirectories: true)

    let setupOptions = LibboxSetupOptions()
    setupOptions.basePath = context.workingDirectory.path
    setupOptions.workingPath = context.workingDirectory.path
    setupOptions.tempPath = context.workingDirectory.path
    setupOptions.logMaxLines = 3000
    setupOptions.debug = false
    setupOptions.crashReportSource = "PacketTunnel"

    var setupError: NSError?
    LibboxSetup(setupOptions, &setupError)
    if let setupError {
      throw NSError(
        domain: "inet.vpn",
        code: -42,
        userInfo: [NSLocalizedDescriptionKey: "Libbox setup failed: \(setupError.localizedDescription)"]
      )
    }

    let platform = ProjectIOSPlatformInterface(
      context: context,
      reloadHandler: { [weak self] in
        try self?.reloadService()
      },
      stopHandler: { [weak self] in
        self?.stop()
      }
    )
    self.platformInterface = platform

    var createError: NSError?
    guard let server = LibboxNewCommandServer(platform, platform, &createError) else {
      throw NSError(
        domain: "inet.vpn",
        code: -43,
        userInfo: [NSLocalizedDescriptionKey: createError?.localizedDescription ?? "Libbox command server creation returned nil."]
      )
    }

    do {
      try server.start()
      commandServer = server
      try startService(server)
    } catch {
      try? server.closeService()
      server.close()
      commandServer = nil
      platformInterface = nil
      throw error
    }
  }

  func stop() {
    if let server = commandServer {
      try? server.closeService()
      server.close()
    }
    commandServer = nil
    platformInterface?.reset()
    platformInterface = nil
  }

  private func reloadService() throws {
    guard let server = commandServer else { return }
    try startService(server)
  }

  private func startService(_ server: LibboxCommandServer) throws {
    let options = LibboxOverrideOptions()
    do {
      try server.startOrReloadService(context.configJSON, options: options)
    } catch {
      throw NSError(
        domain: "inet.vpn",
        code: -44,
        userInfo: [NSLocalizedDescriptionKey: "Libbox service start failed: \(error.localizedDescription)"]
      )
    }
  }
}

private final class ProjectIOSPlatformInterface: NSObject, LibboxPlatformInterfaceProtocol, LibboxCommandServerHandlerProtocol {
  private let context: ObjCSingBoxLaunchContext
  private let reloadHandler: () throws -> Void
  private let stopHandler: () -> Void
  private var networkSettings: NEPacketTunnelNetworkSettings?
  private var nwMonitor: NWPathMonitor?

  init(
    context: ObjCSingBoxLaunchContext,
    reloadHandler: @escaping () throws -> Void,
    stopHandler: @escaping () -> Void
  ) {
    self.context = context
    self.reloadHandler = reloadHandler
    self.stopHandler = stopHandler
    super.init()
  }

  func openTun(_ options: LibboxTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
    guard let options else {
      throw NSError(domain: "inet.vpn", code: -45, userInfo: [NSLocalizedDescriptionKey: "Libbox openTun called without options."])
    }
    guard let ret0_ else {
      throw NSError(domain: "inet.vpn", code: -46, userInfo: [NSLocalizedDescriptionKey: "Libbox openTun called without return pointer."])
    }

    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
    settings.mtu = NSNumber(value: options.getMTU())

    if options.getAutoRoute() {
      let dnsServer = try options.getDNSServerAddress().value
      let dnsSettings = NEDNSSettings(servers: [dnsServer])

      var ipv4Addresses: [String] = []
      var ipv4Masks: [String] = []
      if let iterator = options.getInet4Address() {
        while iterator.hasNext() {
          guard let prefix = iterator.next() else { continue }
          ipv4Addresses.append(prefix.address())
          ipv4Masks.append(prefix.mask())
        }
      }
      if !ipv4Addresses.isEmpty {
        let ipv4Settings = NEIPv4Settings(addresses: ipv4Addresses, subnetMasks: ipv4Masks)
        var routes: [NEIPv4Route] = []
        if let iterator = options.getInet4RouteAddress() {
          while iterator.hasNext() {
            guard let prefix = iterator.next() else { continue }
            routes.append(NEIPv4Route(destinationAddress: prefix.address(), subnetMask: prefix.mask()))
          }
        }
        if routes.isEmpty {
          routes = [NEIPv4Route.default()]
        }
        ipv4Settings.includedRoutes = routes
        var excluded: [NEIPv4Route] = []
        if let iterator = options.getInet4RouteExcludeAddress() {
          while iterator.hasNext() {
            guard let prefix = iterator.next() else { continue }
            excluded.append(NEIPv4Route(destinationAddress: prefix.address(), subnetMask: prefix.mask()))
          }
        }
        ipv4Settings.excludedRoutes = excluded
        settings.ipv4Settings = ipv4Settings
      }

      var ipv6Addresses: [String] = []
      var ipv6Prefixes: [NSNumber] = []
      if let iterator = options.getInet6Address() {
        while iterator.hasNext() {
          guard let prefix = iterator.next() else { continue }
          ipv6Addresses.append(prefix.address())
          ipv6Prefixes.append(NSNumber(value: prefix.prefix()))
        }
      }
      if !ipv6Addresses.isEmpty {
        let ipv6Settings = NEIPv6Settings(addresses: ipv6Addresses, networkPrefixLengths: ipv6Prefixes)
        var routes: [NEIPv6Route] = []
        if let iterator = options.getInet6RouteAddress() {
          while iterator.hasNext() {
            guard let prefix = iterator.next() else { continue }
            routes.append(NEIPv6Route(destinationAddress: prefix.address(), networkPrefixLength: NSNumber(value: prefix.prefix())))
          }
        }
        if routes.isEmpty {
          routes = [NEIPv6Route.default()]
        }
        ipv6Settings.includedRoutes = routes
        var excluded: [NEIPv6Route] = []
        if let iterator = options.getInet6RouteExcludeAddress() {
          while iterator.hasNext() {
            guard let prefix = iterator.next() else { continue }
            excluded.append(NEIPv6Route(destinationAddress: prefix.address(), networkPrefixLength: NSNumber(value: prefix.prefix())))
          }
        }
        ipv6Settings.excludedRoutes = excluded
        settings.ipv6Settings = ipv6Settings
      }

      dnsSettings.matchDomains = [""]
      dnsSettings.matchDomainsNoSearch = true
      settings.dnsSettings = dnsSettings
    }

    if options.isHTTPProxyEnabled() {
      let proxySettings = NEProxySettings()
      let proxyServer = NEProxyServer(address: options.getHTTPProxyServer(), port: Int(options.getHTTPProxyServerPort()))
      proxySettings.httpServer = proxyServer
      proxySettings.httpsServer = proxyServer
      proxySettings.httpEnabled = true
      proxySettings.httpsEnabled = true
      settings.proxySettings = proxySettings
    }

    try applyNetworkSettings(settings)
    networkSettings = settings

    if let tunFd = context.provider.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 {
      ret0_.pointee = tunFd
      return
    }

    let tunFd = LibboxGetTunnelFileDescriptor()
    if tunFd != -1 {
      ret0_.pointee = tunFd
      return
    }

    throw NSError(domain: "inet.vpn", code: -47, userInfo: [NSLocalizedDescriptionKey: "PacketTunnel file descriptor is missing."])
  }

  func usePlatformAutoDetectControl() -> Bool { false }

  func autoDetectControl(_: Int32) throws {}

  func findConnectionOwner(_ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32, destinationAddress: String?, destinationPort: Int32) throws -> LibboxConnectionOwner {
    _ = ipProtocol
    _ = sourceAddress
    _ = sourcePort
    _ = destinationAddress
    _ = destinationPort
    return LibboxConnectionOwner()
  }

  func useProcFS() -> Bool { false }

  func writeLog(_ message: String?) {
    writeDebugMessage(message)
  }

  func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
    guard let listener else { return }
    let monitor = NWPathMonitor()
    nwMonitor = monitor
    let semaphore = DispatchSemaphore(value: 0)
    monitor.pathUpdateHandler = { [weak self] path in
      self?.onUpdateDefaultInterface(listener, path)
      semaphore.signal()
      monitor.pathUpdateHandler = { [weak self] path in
        self?.onUpdateDefaultInterface(listener, path)
      }
    }
    monitor.start(queue: DispatchQueue.global())
    semaphore.wait()
  }

  private func onUpdateDefaultInterface(_ listener: LibboxInterfaceUpdateListenerProtocol, _ path: NWPath) {
    guard path.status != .unsatisfied,
          let defaultInterface = path.availableInterfaces.first
    else {
      listener.updateDefaultInterface("", interfaceIndex: -1, isExpensive: false, isConstrained: false)
      return
    }
    listener.updateDefaultInterface(defaultInterface.name, interfaceIndex: Int32(defaultInterface.index), isExpensive: path.isExpensive, isConstrained: path.isConstrained)
  }

  func closeDefaultInterfaceMonitor(_: LibboxInterfaceUpdateListenerProtocol?) throws {
    nwMonitor?.cancel()
    nwMonitor = nil
  }

  func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
    guard let nwMonitor else {
      return EmptyNetworkInterfaceIterator()
    }
    let path = nwMonitor.currentPath
    if path.status == .unsatisfied {
      return EmptyNetworkInterfaceIterator()
    }
    var interfaces: [LibboxNetworkInterface] = []
    for item in path.availableInterfaces {
      let interface = LibboxNetworkInterface()
      interface.name = item.name
      interface.index = Int32(item.index)
      switch item.type {
      case .wifi:
        interface.type = LibboxInterfaceTypeWIFI
      case .cellular:
        interface.type = LibboxInterfaceTypeCellular
      case .wiredEthernet:
        interface.type = LibboxInterfaceTypeEthernet
      default:
        interface.type = LibboxInterfaceTypeOther
      }
      interfaces.append(interface)
    }
    return ArrayNetworkInterfaceIterator(interfaces)
  }

  func underNetworkExtension() -> Bool { true }

  func includeAllNetworks() -> Bool { false }

  func clearDNSCache() {
    guard let networkSettings else { return }
    try? applyNetworkSettings(networkSettings)
  }

  func readWIFIState() -> LibboxWIFIState? { nil }

  func readWIFISSID() -> String? { nil }

  func serviceStop() throws {
    stopHandler()
  }

  func serviceReload() throws {
    try reloadHandler()
  }

  func getSystemProxyStatus() throws -> LibboxSystemProxyStatus {
    let status = LibboxSystemProxyStatus()
    guard let proxySettings = networkSettings?.proxySettings else {
      return status
    }
    status.available = proxySettings.httpServer != nil
    status.enabled = proxySettings.httpEnabled
    return status
  }

  func setSystemProxyEnabled(_ isEnabled: Bool) throws {
    guard let networkSettings, let proxySettings = networkSettings.proxySettings else {
      return
    }
    proxySettings.httpEnabled = isEnabled
    proxySettings.httpsEnabled = isEnabled
    networkSettings.proxySettings = proxySettings
    try applyNetworkSettings(networkSettings)
    self.networkSettings = networkSettings
  }

  func triggerNativeCrash() throws {
    fatalError("debug native crash")
  }

  func writeDebugMessage(_ message: String?) {
    guard let message, !message.isEmpty else { return }
    NSLog("[libbox-ios] %@", message)
  }

  func send(_ notification: LibboxNotification?) throws {
    guard let notification else { return }
    let content = UNMutableNotificationContent()
    content.title = notification.title
    content.subtitle = notification.subtitle
    content.body = notification.body
    let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: nil)
    let semaphore = DispatchSemaphore(value: 0)
    var sendError: Error?
    UNUserNotificationCenter.current().add(request) { error in
      sendError = error
      semaphore.signal()
    }
    semaphore.wait()
    if let sendError {
      throw sendError
    }
  }

  func startNeighborMonitor(_ listener: LibboxNeighborUpdateListenerProtocol?) throws {
    _ = listener
  }

  func reset() {
    nwMonitor?.cancel()
    nwMonitor = nil
    networkSettings = nil
  }

  private func applyNetworkSettings(_ settings: NEPacketTunnelNetworkSettings?) throws {
    let semaphore = DispatchSemaphore(value: 0)
    var applyError: Error?
    context.provider.setTunnelNetworkSettings(settings) { error in
      applyError = error
      semaphore.signal()
    }
    semaphore.wait()
    if let applyError {
      throw applyError
    }
  }
}

private final class ArrayNetworkInterfaceIterator: NSObject, LibboxNetworkInterfaceIteratorProtocol {
  private var iterator: IndexingIterator<[LibboxNetworkInterface]>
  private var nextValue: LibboxNetworkInterface?

  init(_ items: [LibboxNetworkInterface]) {
    self.iterator = items.makeIterator()
    super.init()
  }

  func hasNext() -> Bool {
    nextValue = iterator.next()
    return nextValue != nil
  }

  func next() -> LibboxNetworkInterface? {
    nextValue
  }
}

private final class EmptyNetworkInterfaceIterator: NSObject, LibboxNetworkInterfaceIteratorProtocol {
  func hasNext() -> Bool { false }
  func next() -> LibboxNetworkInterface? { nil }
}
#endif
