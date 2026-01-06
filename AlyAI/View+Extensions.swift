import SwiftUI

extension View {
    public func background<S: ShapeStyle>(gradient: S) -> some View {
        self.background(gradient)
    }
}
