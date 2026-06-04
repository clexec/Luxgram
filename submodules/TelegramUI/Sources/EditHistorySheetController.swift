#if canImport(SGDeletedMessages)
import Foundation
import UIKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData
import AccountContext

/// Presents full edit history of a message (original + all edits).
public func editHistorySheetController(
    context: AccountContext,
    message: Message,
    present: (ViewController) -> Void
) {
    let versions = message.sgDeletedAttribute.allEditVersions(currentText: message.text)
    guard versions.count > 1 else { return }
    
    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let theme = presentationData.theme
    let strings = presentationData.strings
    
    let lang = strings.baseLanguageCode
    let title = (lang == "ru" ? "История редактирования" : "Edit history")
    
    let controller = EditHistorySheetController(
        theme: theme,
        title: title,
        versions: versions
    )
    present(controller)
}

private final class EditHistorySheetController: ViewController {
    private let theme: PresentationTheme
    private let titleText: String
    private let versions: [String]
    
    init(theme: PresentationTheme, title: String, versions: [String]) {
        self.theme = theme
        self.titleText = title
        self.versions = versions
        super.init(navigationBarPresentationData: NavigationBarPresentationData(
            theme: NavigationBarTheme(rootControllerTheme: theme),
            strings: NavigationBarStrings(
                back: "Back",
                close: "Close"
            )
        ))
        self.navigationPresentation = .modal
        self.title = title
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadDisplayNode() {
        self.displayNode = EditHistorySheetControllerNode(
            theme: self.theme,
            title: self.titleText,
            versions: self.versions,
            dismiss: { [weak self] in
                self?.dismiss()
            }
        )
        self.displayNodeDidLoad()
    }
}

private final class EditHistorySheetControllerNode: ViewControllerTracingNode {
    private let theme: PresentationTheme
    private let versions: [String]
    
    private let scrollView: UIScrollView
    private let contentContainer = UIView()
    private var builtContent = false
    
    init(theme: PresentationTheme, title: String, versions: [String], dismiss: @escaping () -> Void) {
        self.theme = theme
        self.versions = versions
        self.scrollView = UIScrollView()
        super.init()
        self.backgroundColor = theme.list.plainBackgroundColor
    }
    
    override func didLoad() {
        super.didLoad()
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentContainer)
    }
    
    private func buildContentIfNeeded(width: CGFloat) {
        guard width > 0, !builtContent else { return }
        builtContent = true
        
        let insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let spacing: CGFloat = 12
        let maxWidth = width - insets.left - insets.right
        let isRu = Locale.current.identifier.hasPrefix("ru")
        let originalStr = isRu ? "Оригинал" : "Original"
        let editStr = isRu ? "Правка" : "Edit"
        
        var y: CGFloat = 0
        for (index, text) in self.versions.enumerated() {
            let versionLabel = UILabel()
            versionLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            versionLabel.textColor = self.theme.list.itemSecondaryTextColor
            versionLabel.text = index == 0 ? originalStr : "\(editStr) \(index)"
            versionLabel.numberOfLines = 1
            versionLabel.sizeToFit()
            versionLabel.frame = CGRect(x: insets.left, y: y, width: maxWidth, height: versionLabel.bounds.height)
            self.contentContainer.addSubview(versionLabel)
            y += versionLabel.bounds.height + 4
            
            let textLabel = UILabel()
            textLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            textLabel.textColor = self.theme.list.itemPrimaryTextColor
            textLabel.text = text
            textLabel.numberOfLines = 0
            textLabel.lineBreakMode = .byWordWrapping
            let size = textLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            textLabel.frame = CGRect(x: insets.left, y: y, width: maxWidth, height: size.height)
            self.contentContainer.addSubview(textLabel)
            y += size.height + spacing
        }
        
        self.contentContainer.frame = CGRect(x: 0, y: 0, width: width, height: y)
        self.scrollView.contentSize = CGSize(width: width, height: y)
    }
    
    override func layout() {
        super.layout()
        let width = self.bounds.width
        self.scrollView.frame = self.bounds
        buildContentIfNeeded(width: width)
        if builtContent {
            self.scrollView.contentSize = self.contentContainer.frame.size
        }
    }
}
#endif
