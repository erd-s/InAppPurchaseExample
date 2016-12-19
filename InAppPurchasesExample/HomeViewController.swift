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
		case .requestProduct: outputText = "requesting product"
		case .requestPayment: outputText = "requesting payment"
		case .paymentQueued: outputText = "payment queued"
		case .paymentReceived:
			outputText = "payment received"
		case .productDelivered:
			outputText = "product delivered"
			spinner.stopAnimating()
		case .errorPurchasing: outputText = "error purchasing"
		}
		
		
		outputLabel.text = outputText
	}
	
	func errorPurchasing(error: Error) {
		spinner.stopAnimating()
		outputLabel.text = outputLabel.text?.appending("\n\(error.localizedDescription)")
	}
}









