//
//  OrangeButton.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-03-21.
//

import UIKit

class OrangeButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 25
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                highlight()
            }else{
                unhighlight()
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.titleLabel?.alpha = 1
                self.alpha = 1
            }else{
                self.titleLabel?.alpha = 0.5
                self.alpha = 0.5
            }
        }
    }

    func highlight(){
        UIView.transition(with: self, duration: 0.4, options: .curveLinear, animations: {
            self.backgroundColor = UIColor(hexString: "F19D65", withAlpha: 0.5)
            self.backgroundColor = UIColor.flatOrange()?.withAlphaComponent(0.5)
            self.imageView?.tintColor = UIColor(hexString: "FFFFFF", withAlpha: 0.5)
        }, completion: nil)
    }
    func unhighlight(){
        UIView.transition(with: self, duration: 0.4, options: .curveLinear, animations: {
            self.backgroundColor = UIColor.flatOrange()
            self.imageView?.tintColor = UIColor(hexString: "FFFFFF")
        }, completion: nil)
    }
}
