import SwiftUI
import CoreGraphics

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrangeSubviews(sizes: sizes, in: proposal.width ?? 0)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var origin = bounds.origin
        var maxY: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y = maxY + spacing
            }
            
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            maxY = max(maxY, origin.y + size.height)
        }
    }
    
    private func arrangeSubviews(sizes: [CGSize], in width: CGFloat) -> CGSize {
        var origin = CGPoint.zero
        var maxY: CGFloat = 0
        
        for size in sizes {
            if origin.x + size.width > width {
                origin.x = 0
                origin.y = maxY + spacing
            }
            
            origin.x += size.width + spacing
            maxY = max(maxY, origin.y + size.height)
        }
        
        return CGSize(width: width, height: maxY)
    }
} 