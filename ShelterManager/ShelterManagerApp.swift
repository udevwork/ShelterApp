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
    @StateObject var user = UserEnv()
    @StateObject var tabbarBages = TabbarBager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if user.isLogged {
                    if (user.isAdmin ?? false) || (user.isModerator ?? false) {
                        TabView {
                            BuildingsListView()
                                .tabItem { Label("Buildings", systemImage: "building.2.fill") }
                            ResidentsRemoteList(model: .init())
                                .tabItem { Label("Users", systemImage: "person.2.fill") }
                            NewNotesAlertsView(model: .init(tabbarBager: tabbarBages))
                                .tabItem { Label("Alerts", systemImage: "note.text") }
                                .badge(tabbarBages.newNotesAlertsCount)
                            AdministratorProfileView()
                                .tabItem { Label("Admin panel", systemImage: "wrench.and.screwdriver.fill") }
                        }
                    } else {
                        NavigationStack {
                            ResidentProfileView( model: .init(userID: user.id), editble: false)
                        }
                    }
                } else {
                    SignInView()
                }
            }
            .environmentObject(user)
            .environmentObject(tabbarBages)
        }
    }
}

class TabbarBager: ObservableObject {
    @Published var newNotesAlertsCount: Int = 0
}







