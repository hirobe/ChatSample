//
//  ViewController.swift
//  RxSwiftChatSample
//
//  Created by hirobe on 2019/06/27.
//  Copyright © 2019 Bunguu inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performSegue(withIdentifier: "ShowSignUp", sender: self)
    }


}

