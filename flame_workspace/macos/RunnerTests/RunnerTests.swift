import Cocoa
import FlutterMacOS
import XCTest
@testable import flame_workspace

class RunnerTests: XCTestCase {
  let primary = CGRect(x: 0, y: 0, width: 1280, height: 760)

  func testFirstLaunchFitsVisibleScreen() {
    let frame = EditorWindowPlacement.frame(saved: nil, visibleFrames: [primary])
    XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 1280, height: 760))
  }

  func testRestoresValidFrameOnSecondMonitor() {
    let secondary = CGRect(x: 1280, y: -100, width: 1600, height: 900)
    let saved = CGRect(x: 1400, y: 50, width: 1050, height: 700)
    XCTAssertEqual(EditorWindowPlacement.frame(saved: saved, visibleFrames: [primary, secondary]), saved)
  }

  func testRemovedMonitorRecentersAndResizes() {
    let saved = CGRect(x: 2000, y: 300, width: 1800, height: 1000)
    XCTAssertEqual(EditorWindowPlacement.frame(saved: saved, visibleFrames: [primary]), primary)
  }

  func testPartiallyVisibleAndInvalidFramesAreConstrained() {
    let edge = CGRect(x: 1250, y: -600, width: 900, height: 800)
    XCTAssertEqual(EditorWindowPlacement.frame(saved: edge, visibleFrames: [primary]),
                   CGRect(x: 380, y: 0, width: 900, height: 760))
    let invalid = CGRect(x: CGFloat.nan, y: 20, width: 800, height: 600)
    XCTAssertEqual(EditorWindowPlacement.frame(saved: invalid, visibleFrames: [primary]),
                   CGRect(x: 0, y: 0, width: 1280, height: 760))
  }
}
