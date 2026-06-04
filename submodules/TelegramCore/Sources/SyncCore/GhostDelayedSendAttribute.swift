import Foundation
import Postbox

/// When present, the message is shown as "sent" in UI but actual send to server is delayed until sendAt (Unix timestamp).
/// Used for "ghost mode" / delayed send: message appears immediately with one check, server receives it after delay.
public final class GhostDelayedSendAttribute: MessageAttribute {
    public let sendAt: Int32

    public init(sendAt: Int32) {
        self.sendAt = sendAt
    }

    required public init(decoder: PostboxDecoder) {
        self.sendAt = decoder.decodeInt32ForKey("t", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.sendAt, forKey: "t")
    }
}
