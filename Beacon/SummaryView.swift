//
//  SummaryView.swift
//  Hal
//
//  Created by Thibault Imbert on 10/11/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import Macaw

class SummaryView: MacawView {
    
    required init?(coder aDecoder: NSCoder) {
        let text = Text(text: "Hello, World!", place: .move(dx: 145, dy: 100))
        super.init(node: text, coder: aDecoder)
    }
}
