import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK key (D-A62, D-A81): `GMSApiKey` in Info.plist expands
    // the build setting SHAHM_GOOGLE_MAPS_API_KEY (set outside source
    // control, e.g. an untracked xcconfig). Without a key nothing is
    // provided, and the app does not build a map (it shows "map
    // unavailable"), because the Dart side is only enabled by the
    // SHAHM_GOOGLE_MAPS define when the keys are provisioned.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !key.isEmpty
    {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
