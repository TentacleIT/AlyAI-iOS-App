import SwiftUI
import Combine

final class UserSession: ObservableObject {
    @AppStorage("userName") var userName: String = ""
}
