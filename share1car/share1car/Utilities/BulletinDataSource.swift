
import UIKit
import BLTNBoard
import SafariServices

enum BulletinDataSource {

    // MARK: - Pages


    static func makeProfilePicRequestPage() -> FeedbackPageBLTNItem {

        let page = FeedbackPageBLTNItem(title: "Add your photo")
        page.image = UIImage(named: "RoundedIcon")

        page.descriptionText = "We need your photo to start finding carpools for you."
        page.actionButtonTitle = "Upload photo"
        

        page.appearance.shouldUseCompactDescriptionText = true
        page.isDismissable = false
                
        

        return page

    }
    
    static func makeCarpoolWaitingForConfirmationPage(title: String) -> FeedbackPageBLTNItem {
    
           let page = FeedbackPageBLTNItem(title: title)
        
            page.actionButton?.isHidden = true
           page.alternativeButtonTitle = "Cancel request"
           page.isDismissable = false

           let tintColor: UIColor
           if #available(iOS 13.0, *) {
               tintColor = .systemRed
           } else {
               tintColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
           }
//           page.appearance.actionButtonColor = tintColor
          

           return page

    }
    
    static func makeCarpoolProgressUpdatePage(title: String, cancelTitle: String) -> FeedbackPageBLTNItem {

        let page = FeedbackPageBLTNItem(title: title)
     
        page.actionButtonTitle = cancelTitle
        page.actionButton?.setTitleColor(.red, for: .normal)
        page.isDismissable = false
        page.shouldStartWithActivityIndicator = true

        let tintColor: UIColor
        if #available(iOS 13.0, *) {
            tintColor = .systemRed
        } else {
            tintColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        }
        page.appearance.actionButtonColor = tintColor
       

        return page

    }

    
    
    static func makeCarpoolRequestPage(
        title: String,
        photoURL: String,
        mainTitle: String, subtitle: String, priceText: String) -> CarpoolAlertBTLNItem {

    
        let page = CarpoolAlertBTLNItem(topTitle: title , mainTitle: mainTitle, subtitle: subtitle, photoURL: photoURL, priceText: priceText )
        
        page.actionButtonTitle = "Send request"
        
        
        let tintColor: UIColor
        if #available(iOS 13.0, *) {
            tintColor = .systemGreen
        } else {
            tintColor = #colorLiteral(red: 0.1199134365, green: 0.7884555459, blue: 0.7099849582, alpha: 1)
        }
        page.appearance.actionButtonColor = tintColor
        page.appearance.alternativeButtonTitleColor = .red
        

        page.appearance.shouldUseCompactDescriptionText = true
        page.isDismissable = true
                
        page.alternativeButtonTitle = "Cancel"

        return page

    }

    static func makeIntroPage() -> FeedbackPageBLTNItem {

        let page = FeedbackPageBLTNItem(title: "Welcome to\nPetBoard")
        page.image = #imageLiteral(resourceName: "RoundedIcon")
        page.imageAccessibilityLabel = "😻"
        page.appearance = makeLightAppearance()

        page.descriptionText = "Discover curated images of the best pets in the world."
        page.actionButtonTitle = "Configure"
        page.alternativeButtonTitle = "Privacy Policy"

        page.isDismissable = true
        page.shouldStartWithActivityIndicator = true

        page.presentationHandler = { item in

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                item.manager?.hideActivityIndicator()
            }

        }

        page.actionHandler = { item in
            item.manager?.displayNextItem()
        }

        page.alternativeHandler = { item in
            let privacyPolicyVC = SFSafariViewController(url: URL(string: "https://example.com")!)
            item.manager?.present(privacyPolicyVC, animated: true)
        }

        page.next = makeTextFieldPage()

        return page

    }

    /**
     * Create the textfield page.
     *
     * This creates a `TextFieldBulletinPage` with: a title, an error label and a textfield.
     *
     * The keyboard return button presents the next item (the notification page).
     */
    static func makeTextFieldPage() -> TextFieldBulletinPage {

        let page = TextFieldBulletinPage(title: "Phone number")
        page.isDismissable = true
        page.descriptionText = "Do you want to enter your mobile number? It will only be shown to your ride partners. This makes it easier to find each other and allows contact if something does not work out"
        page.actionButtonTitle = "Continue"



        return page

    }
    
    static func makeDatePage() -> DatePickerBLTNItem {

        let page = DatePickerBLTNItem(title: "Plan a Carpool")
        page.descriptionText = "When you want to start carpool?"
        page.isDismissable = true
        page.actionButtonTitle = "Done"
        let tintColor: UIColor
        if #available(iOS 13.0, *) {
            tintColor = .systemGreen
        } else {
            tintColor = #colorLiteral(red: 0.195412606, green: 0.6979529858, blue: 0.6217982173, alpha: 1)
        }
        page.appearance.actionButtonColor = tintColor

        return page

    }
    


    /**
     * Create the notifications page.
     *
     * This creates a `FeedbackPageBLTNItem` with: a title, an image, a description text, an action
     * and an alternative button.
     *
     * The action and the alternative buttons present the next item (the location page). The action button
     * starts a notification registration request.
     */

    static func makeNotitificationsPage() -> FeedbackPageBLTNItem {

        let page = FeedbackPageBLTNItem(title: "Receive Carpool Updates")
        page.image = #imageLiteral(resourceName: "NotificationPrompt")
        page.imageAccessibilityLabel = "Notifications Icon"

        page.descriptionText = "Receive push notifications when carpool is in progress."
        page.actionButtonTitle = "Subscribe"

        page.isDismissable = false

        page.actionHandler = { item in
            NotificationsManager.shared.registerForNotifications()
            item.manager?.dismissBulletin()
        }


       

        return page

    }

    /**
     * Create the location page.
     *
     * This creates a `FeedbackPageBLTNItem` with: a title, an image, a compact description text,
     * an action and an alternative button.
     *
     * The action and the alternative buttons present the next item (the animal choice page). The action button
     * requests permission for location.
     */

    static func makeLocationPage() -> FeedbackPageBLTNItem {

        let page = FeedbackPageBLTNItem(title: "See drivers near-by")
        page.image = #imageLiteral(resourceName: "LocationPrompt")
        page.imageAccessibilityLabel = "Location Icon"

        page.descriptionText = "We need to know your location to give you accurate updates about carpools near you. You can update your choice later in the app settings."
        page.actionButtonTitle = "Continue"

        page.appearance.shouldUseCompactDescriptionText = true
        page.isDismissable = false
        
         page.next = makeNotitificationsPage()


        return page

    }



    /**
     * Create the location page.
     *
     * This creates a `PageBLTNItem` with: a title, an image, a description text, and an action
     * button. The item can be dismissed. The tint color of the action button is customized.
     *
     * The action button dismisses the bulletin. The alternative button pops to the root item.
     */

    static func makeCompletionPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Setup Completed")
        page.image = #imageLiteral(resourceName: "IntroCompletion")
        page.imageAccessibilityLabel = "Checkmark"

        let tintColor: UIColor
        if #available(iOS 13.0, *) {
            tintColor = .systemGreen
        } else {
            tintColor = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        }
        page.appearance.actionButtonColor = tintColor
        page.appearance.imageViewTintColor = tintColor

        page.appearance.actionButtonTitleColor = .white

        page.descriptionText = "PetBoard is ready for you to use. Happy browsing!"
        page.actionButtonTitle = "Get started"
        page.alternativeButtonTitle = "Replay"

        page.isDismissable = true

        page.dismissalHandler = { item in
            NotificationCenter.default.post(name: .SetupDidComplete, object: item)
        }

        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }

        page.alternativeHandler = { item in
            item.manager?.popToRootItem()
        }

        return page

    }

    // MARK: - User Defaults

    /// The current favorite tab index.
    static var favoriteTabIndex: Int {
        get {
            return UserDefaults.standard.integer(forKey: "PetBoardFavoriteTabIndex")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PetBoardFavoriteTabIndex")
        }
    }

    /// Whether user completed setup.
    static var userDidCompleteSetup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "PetBoardUserDidCompleteSetup")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PetBoardUserDidCompleteSetup")
        }
    }

    /// Whether to use the Avenir font instead of San Francisco.
    static var useAvenirFont: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "UseAvenirFont")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "UseAvenirFont")
        }
    }

}

// MARK: - Appearance

extension BulletinDataSource {

    static func makeLightAppearance() -> BLTNItemAppearance {

        let appearance = BLTNItemAppearance()

        if useAvenirFont {

            appearance.titleFontDescriptor = UIFontDescriptor(name: "AvenirNext-Medium", matrix: .identity)
            appearance.descriptionFontDescriptor = UIFontDescriptor(name: "AvenirNext-Regular", matrix: .identity)
            appearance.buttonFontDescriptor = UIFontDescriptor(name: "AvenirNext-DemiBold", matrix: .identity)

        }

        return appearance

    }

    static func currentFontName() -> String {
        return useAvenirFont ? "Avenir Next" : "San Francisco"
    }

}

// MARK: - Notifications

extension Notification.Name {

    /**
     * The favorite tab index did change.
     *
     * The user info dictionary contains the following values:
     *
     * - `"Index"` = an integer with the new favorite tab index.
     */

    static let FavoriteTabIndexDidChange = Notification.Name("PetBoardFavoriteTabIndexDidChangeNotification")

    /**
     * The setup did complete.
     *
     * The user info dictionary is empty.
     */

    static let SetupDidComplete = Notification.Name("PetBoardSetupDidCompleteNotification")

}
