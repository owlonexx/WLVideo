//
//  ViewController.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit

let screenHeight = UIScreen.main.bounds.size.height
let screenWidth = UIScreen.main.bounds.size.width

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    @IBAction func buttonClick(_ sender: Any) {
        present(WLCameraController(), animated: true, completion: nil)
    }
}

