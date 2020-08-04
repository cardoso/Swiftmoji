//
//  ViewController.swift
//  StreamojiMacExample
//
//  Created by Carlo Rapisarda on 2020-08-04.
//

import Cocoa
import Streamoji

class ViewController: NSViewController {

    @IBOutlet private var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.font = .systemFont(ofSize: 30)
        textView.configureEmojis([
            "test": .character("😇"),
            "let_me_in": .imageUrl("https://github.com/GetStream/Streamoji/blob/main/meta/emojis/let_me_in.gif?raw=true"),
            "hey": .imageUrl("https://media.giphy.com/media/l2QEdvfq7bCCk6qOI/giphy.gif"),
        ])
    }
}
