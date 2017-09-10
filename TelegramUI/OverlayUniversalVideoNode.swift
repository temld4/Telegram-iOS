import Foundation
import AsyncDisplayKit
import SwiftSignalKit
import Display
import TelegramCore

final class OverlayUniversalVideoNode: OverlayMediaItemNode {
    private let content: UniversalVideoContent
    private let videoNode: UniversalVideoNode
    
    private var validLayoutSize: CGSize?
    
    override var group: OverlayMediaItemNodeGroup? {
        return OverlayMediaItemNodeGroup(rawValue: 0)
    }
    
    init(account: Account, manager: UniversalVideoContentManager, content: UniversalVideoContent, expand: @escaping () -> Void, close: @escaping () -> Void) {
        self.content = content
        var togglePlayPauseImpl: (() -> Void)?
        var closeImpl: (() -> Void)?
        let decoration = OverlayVideoDecoration(togglePlayPause: {
            togglePlayPauseImpl?()
        }, expand: {
            expand()
        }, close: {
            closeImpl?()
        })
        self.videoNode = UniversalVideoNode(account: account, manager: manager, decoration: decoration, content: content, priority: .overlay)
        
        super.init()
        
        togglePlayPauseImpl = { [weak self] in
            self?.videoNode.togglePlayPause()
        }
        closeImpl = { [weak self] in
            if let strongSelf = self {
                strongSelf.layer.animateScale(from: 1.0, to: 0.1, duration: 0.25, removeOnCompletion: false, completion: { _ in
                    self?.dismiss()
                    close()
                })
                strongSelf.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25, removeOnCompletion: false)
            }
        }

        self.clipsToBounds = true
        self.cornerRadius = 4.0
        
        self.addSubnode(self.videoNode)
        self.videoNode.ownsContentNodeUpdated = { [weak self] value in
            if let strongSelf = self {
                strongSelf.hasAttachedContext = value
                strongSelf.hasAttachedContextUpdated?(value)
            }
        }
        
        self.videoNode.canAttachContent = true
    }
    
    override func didLoad() {
        super.didLoad()
    }
    
    override func layout() {
        self.updateLayout(self.bounds.size)
    }
    
    override func preferredSizeForOverlayDisplay() -> CGSize {
        return self.content.dimensions.aspectFitted(CGSize(width: 300.0, height: 300.0))
    }
    
    override func updateLayout(_ size: CGSize) {
        if size != self.validLayoutSize {
            self.updateLayoutImpl(size)
        }
    }
    
    private func updateLayoutImpl(_ size: CGSize) {
        self.validLayoutSize = size
        
        self.videoNode.frame = CGRect(origin: CGPoint(), size: size)
        self.videoNode.updateLayout(size: size, transition: .immediate)
    }
}
