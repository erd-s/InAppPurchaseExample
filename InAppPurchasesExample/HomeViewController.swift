//  Created by Christopher Erdos on 12/18/16.
//  Copyright © 2016 Mouth. All rights reserved.

import Foundation
import UIKit

class HomeViewController: UIViewController {
	//--------------------------------------
	// MARK: - Variables
	//--------------------------------------
	var purchaseManager: PurchaseManager!
	
	//--------------------------------------
	// MARK: - Outlets
	//--------------------------------------
	@IBOutlet weak var yearlyButton: UIButton!
	@IBOutlet weak var weeklyButton: UIButton!
	@IBOutlet weak var outputLabel: UILabel!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	
	//--------------------------------------
	// MARK: - View/Lifecycle
	//--------------------------------------
	override func viewDidLoad() {
		super.viewDidLoad()
		
		purchaseManager = PurchaseManager()
		purchaseManager.delegate = self
		
	}
	
	//--------------------------------------
	// MARK: - Actions
	//--------------------------------------
	@IBAction func yearlyButtonTapped(_ sender: UIButton) {
		spinner.startAnimating()
		purchaseManager.subscribe(type: .yearly)
	}
	
	
	@IBAction func weeklyButtonTapped(_ sender: UIButton) {
		spinner.startAnimating()
		purchaseManager.subscribe(type: .weekly)
	}
	
	
	//--------------------------------------
	// MARK: - Segue
	//--------------------------------------
	
}

extension HomeViewController: PurchaseManagerDelegate {
	func statusUpdated(status: PurchaseManager.PurchaseStatus) {
		var outputText: String!
		
		switch status {
		case .productRequested: outputText = "requesting product from apple"
		case .paymentRequested: outputText = "requesting payment from user"
		case .paymentSent: outputText = "payment sent by user"
		case .paymentReceived:
			outputText = "payment received by apple"
			spinner.stopAnimating()
			/* deliver product here */
		case .errorPurchasing: outputText = "error purchasing"
		}
		
		
		outputLabel.text = outputText
	}
	
	func errorPurchasing(error: Error) {
		spinner.stopAnimating()
		outputLabel.text = outputLabel.text?.appending("\n\(error.localizedDescription)")
	}
}









