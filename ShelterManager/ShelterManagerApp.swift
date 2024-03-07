import SwiftUI
import FirebaseCore
import FirebaseAuth
import AlertToast


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        RealmBackgroundHelper().deleteAllMarkedDeletedObjects()
        return true
    }
}

@main
struct ShelterManagerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Env
    @StateObject var clipBoard = InAppClipboard()
    @StateObject var user = UserEnv()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if user.isLoading == false {
                    if user.isLogged {
                        if (user.isAdmin ?? false) {
                            TabView {
                                BuildingsListView()
                                    .tabItem { Label("Surface", systemImage: "1.circle.fill") }
                                BuildingsListView()
                                    .tabItem { Label("Surface", systemImage: "2.circle.fill") }
                                AdministratorProfileView()
                                    .tabItem { Label("Admin panel", systemImage: "person.crop.circle.fill") }
                               
                            }
                            .environmentObject(clipBoard)
                            .environmentObject(user)
                        } else {
                            ResidentProfileView(model: ResidentProfileModel(userID: UserEnv.current!.uid))
                            .environmentObject(user)
                        }
                    } else {
                        SignInView()
                            .environmentObject(user)
                    }
                } else {
                    LoadingView()
                }
            }.toast(isPresenting: $user.isLoading) {
                AlertToast(type: .loading, title: "Account", subTitle: "Loading")
            }
        }
    }
}









