//
//  ViewController.swift
//  DomainManager
//
//  Created by BJSTTLP185 on 2025/6/30.
//

import UIKit

class ViewController: UIViewController {
    let checker = DomainLatencyChecker(domains: [
        "www.baidu.com",
        "www.sogou.com",
        "www.icloud.com",
        "www.dianping.com"
    ])
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        checkDomains()
    }

    func checkDomains() {
        checker.findFastestDomain { [weak self] fastestDomain in
            guard let domain = fastestDomain else {
                print("所有域名检测失败")
                return
            }
            print("最优节点: \(domain)")
            
        }
    }
}

