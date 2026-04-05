import Foundation
import NetworkExtension

final class LibboxRuntimeFactory: NSObject, IOSSingBoxRuntimeFactory {
  func createRuntime(_ context: ObjCSingBoxLaunchContext) throws -> AnyObject {
    return OfficialLibboxAppleRuntime(context: context)
  }
}
