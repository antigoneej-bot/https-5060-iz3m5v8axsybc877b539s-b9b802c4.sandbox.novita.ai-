import Flutter
import UIKit
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var playbackChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "garden/background_audio", binaryMessenger: controller.binaryMessenger)
      playbackChannel = channel
      let commands = MPRemoteCommandCenter.shared()
      commands.playCommand.addTarget { [weak self] _ in
        self?.playbackChannel?.invokeMethod("play", arguments: nil); return .success
      }
      commands.pauseCommand.addTarget { [weak self] _ in
        self?.playbackChannel?.invokeMethod("pause", arguments: nil); return .success
      }
      commands.stopCommand.addTarget { [weak self] _ in
        self?.playbackChannel?.invokeMethod("stop", arguments: nil); return .success
      }
      channel.setMethodCallHandler { call, reply in
        switch call.method {
        case "start":
          UIApplication.shared.beginReceivingRemoteControlEvents()
          commands.playCommand.isEnabled = true
          commands.pauseCommand.isEnabled = true
          commands.stopCommand.isEnabled = true
          reply(nil)
        case "update":
          let data = call.arguments as? [String: Any] ?? [:]
          let playing = data["playing"] as? Bool ?? false
          MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: data["title"] as? String ?? "마음냥 정원 명상",
            MPMediaItemPropertyArtist: "마음냥 정원",
            MPMediaItemPropertyPlaybackDuration: ((data["duration"] as? NSNumber)?.doubleValue ?? 0) / 1000,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: ((data["position"] as? NSNumber)?.doubleValue ?? 0) / 1000,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? ((data["speed"] as? NSNumber)?.doubleValue ?? 1) : 0
          ]
          reply(nil)
        case "stop":
          commands.playCommand.isEnabled = false
          commands.pauseCommand.isEnabled = false
          commands.stopCommand.isEnabled = false
          MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
          UIApplication.shared.endReceivingRemoteControlEvents()
          reply(nil)
        default: reply(FlutterMethodNotImplemented)
        }
      }
    }
    return result
  }
}
