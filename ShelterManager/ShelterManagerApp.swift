import SwiftUI
import FirebaseCore
import FirebaseAuth
import AlertToast


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        defSettings()
        FirebaseApp.configure()
        RealmBackgroundHelper().deleteAllMarkedDeletedObjects()
        return true
    }
    
    private func defSettings() {
        UserDefaults.standard.register(defaults: ["buildingPhotoEnabled": true,
                                                  "buildingDitailPhotoEnabled": true,
                                                  "userPhotoEnabled": true,
                                                  "extremeImageCompressionEnabled": true])
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
                                    .tabItem { Label("Buildings", systemImage: "building.2.fill") }
                                ResidentsRemoteList(model: .init())
                                    .tabItem { Label("Users", systemImage: "person.2.fill") }
                                AdministratorProfileView()
                                    .tabItem { Label("Admin panel", systemImage: "wrench.and.screwdriver.fill") }
                            }
                            .environmentObject(clipBoard)
                            .environmentObject(user)
                        } else {
                            ResidentProfileView( model: .init(userID: user.id), editble: false)
                                .environmentObject(user)
                        }
                    } else {
                        SignInView()
                            .environmentObject(user)
                    }
                } else {
                    LoadingView()
                }
            }
        }
    }
}









