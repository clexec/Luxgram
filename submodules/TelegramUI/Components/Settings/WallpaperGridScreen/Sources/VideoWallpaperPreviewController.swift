import Foundation
import UIKit
import AVFoundation
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext
import TelegramUIPreferences

public final class VideoWallpaperPreviewController: ViewController {
    private let context: AccountContext
    private let videoURL: URL
    private let onSave: (URL) -> Void
    
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    
    public init(context: AccountContext, videoURL: URL, onSave: @escaping (URL) -> Void) {
        self.context = context
        self.videoURL = videoURL
        self.onSave = onSave
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: context.sharedContext.currentPresentationData.with { $0 }))
        self.navigationPresentation = .modal
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadDisplayNode() {
        self.displayNode = VideoWallpaperPreviewControllerNode(context: self.context, videoURL: self.videoURL, cancel: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }, save: { [weak self] in
            guard let self else { return }
            self.onSave(self.videoURL)
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        (self.displayNode as? VideoWallpaperPreviewControllerNode)?.pause()
    }
    
    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        (self.displayNode as? VideoWallpaperPreviewControllerNode)?.containerLayoutUpdated(layout, transition: transition)
    }
}

private final class VideoWallpaperPreviewControllerNode: ASDisplayNode {
    private let context: AccountContext
    private let videoURL: URL
    private let cancel: () -> Void
    private let save: () -> Void
    
    private let videoContainerNode = ASDisplayNode()
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    
    private let cancelButton: HighlightableButtonNode
    private let saveButton: HighlightableButtonNode
    
    private var validLayout: ContainerViewLayout?
    
    init(context: AccountContext, videoURL: URL, cancel: @escaping () -> Void, save: @escaping () -> Void) {
        self.context = context
        self.videoURL = videoURL
        self.cancel = cancel
        self.save = save
        self.cancelButton = HighlightableButtonNode()
        self.saveButton = HighlightableButtonNode()
        super.init()
        self.backgroundColor = .black
        
        self.addSubnode(self.videoContainerNode)
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.cancelButton.setTitle(presentationData.strings.Common_Cancel, with: .systemFont(ofSize: 17, weight: .regular), with: .white, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(self.cancelPressed), forControlEvents: .touchUpInside)
        self.addSubnode(self.cancelButton)
        
        self.saveButton.setTitle(presentationData.strings.Common_Done, with: .systemFont(ofSize: 17, weight: .semibold), with: presentationData.theme.list.itemAccentColor, for: .normal)
        self.saveButton.addTarget(self, action: #selector(self.savePressed), forControlEvents: .touchUpInside)
        self.addSubnode(self.saveButton)
        
        self.setupVideo()
    }
    
    private func setupVideo() {
        let item = AVPlayerItem(url: self.videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.videoGravity = .resizeAspectFill
        self.videoContainerNode.layer.addSublayer(playerLayer)
        self.player = queuePlayer
        self.playerLayer = playerLayer
        self.looper = looper
        // Use ambient audio session so preview does not interrupt music
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        queuePlayer.play()
    }
    
    func pause() {
        self.player?.pause()
    }
    
    @objc private func cancelPressed() {
        self.cancel()
    }
    
    @objc private func savePressed() {
        self.save()
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.validLayout = layout
        let bounds = CGRect(origin: .zero, size: layout.size)
        transition.updateFrame(node: self.videoContainerNode, frame: bounds)
        self.playerLayer?.frame = bounds
        
        let bottomInset = layout.insets(options: .statusBar).bottom + 34
        let cancelInset: CGFloat = 16
        let saveInset: CGFloat = 16
        transition.updateFrame(node: self.cancelButton, frame: CGRect(x: cancelInset, y: layout.size.height - bottomInset - 44, width: 100, height: 44))
        transition.updateFrame(node: self.saveButton, frame: CGRect(x: layout.size.width - 100 - saveInset, y: layout.size.height - bottomInset - 44, width: 100, height: 44))
    }
}
