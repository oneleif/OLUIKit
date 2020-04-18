import XCTest
@testable import OLUIKit

final class OLUIKitTests: XCTestCase {
    @available(iOS 13.0, *)
    func testSwiftUIView() {
        let view = SwiftUIView {
            UIView()
        }
        
//        XCTAssertEqual(type(of: view.wrappedView).description, UIView.self.description)
    }
}
