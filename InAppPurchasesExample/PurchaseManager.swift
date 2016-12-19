//
//  PurchaseManager.swift
//  InAppPurchasesExample
//
//  Created by Christopher Erdos on 12/18/16.
//  Copyright © 2016 Mouth. All rights reserved.
//

import Foundation
import PromiseKit
import StoreKit

/*-------------------------------------------*/
//TODO: Check user subscription on startup: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/DeliverProduct.html#//apple_ref/doc/uid/TP40008267-CH5-SW3

protocol PurchaseManagerDelegate {
	func statusUpdated(status: PurchaseManager.PurchaseStatus)
	func errorPurchasing(error: Error)
}

/**
Manager object to help make IAPs. Currently does not support restoring purchases.
*/
class PurchaseManager: NSObject {
	//--------------------------------------
	// MARK: - Properties
	//--------------------------------------
	/* you can add product ID's here or directly in the `getProducts` function */
	var productRequest: SKProductsRequest!
	var products: [SKProduct]!
	var payment: SKMutablePayment!
	var delegate: PurchaseManagerDelegate!
	let sharedSecret = "a193c8b409054cce86de22bba0797575"
	
	//--------------------------------------
	// MARK: - Init
	//--------------------------------------
	override init() {
		super.init()
		
		SKPaymentQueue.default().add(self)
	}
	
	//--------------------------------------
	//	1. Call `purchaseManager.subscribe(type)` in View Controller.
	//	2. Purchase Manager requests products of `SubType`.
	//	3. Once products are delivered, requests payment.
	//	4. Once payment has been received, delegate function
	//		`statusUpdated` shows .paymentReceived.
	//  5. View controller gets status updates as you go, then delivers the product.
	//--------------------------------------
	/**
	Catch-all for adding a subscription. One-line call in EnterInformationVC.
	*/
	func subscribe(type: SubType) {
		getProducts(sub: type)
	}
	
	
	/**
	Get products first.
	
	- parameter sub: `SubType` includes `.yearly` & `.weekly`.
	*/
	func getProducts(sub: SubType) {
		delegate.statusUpdated(status: .productRequested)
		
		let yr: Set = ["1yr"]
		let wk: Set = ["1wk"]
		let yrReq = SKProductsRequest(productIdentifiers: yr)
		let wkReq = SKProductsRequest(productIdentifiers: wk)
		
		productRequest = sub == .yearly ? yrReq : wkReq
		productRequest.delegate = self
		productRequest.start()
		
	}
	
	/**
	Requests payment for a specific product.
	
	- parameter product: `SKProduct` to request payment for.
	- parameter quantity: How many of a specific product to purchase. Default quantity is 1.
	*/
	func requestPayment(product: SKProduct, quantity: Int = 1) -> Promise<Void> {
		return Promise { fulfill, reject in
			payment = SKMutablePayment(product: product)
			payment.quantity = quantity
			
			if SKPaymentQueue.canMakePayments() {
				SKPaymentQueue.default().add(payment)
			} else {
				reject(NSError(domain: "9999", code: 99, userInfo: nil))
			}
			
			
			fulfill()
		}
	}
	
	//--------------------------------------
	// MARK: - Support Enums
	//--------------------------------------
	enum SubType {
		case yearly
		case weekly
	}
	
	enum PurchaseStatus {
		case productRequested
		case paymentRequested
		case paymentSent
		case paymentReceived
		case errorPurchasing
	}
}



//--------------------------------------
// MARK: - Product Request Delegate
//--------------------------------------
extension PurchaseManager: SKProductsRequestDelegate {
	func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		products = response.products

		/* shows invalid product IDs */
		if response.invalidProductIdentifiers.count > 0 {
			self.delegate.errorPurchasing(error: NSError(domain: "Purchasing Error", code: 999, userInfo: [NSLocalizedDescriptionKey: "invalid product IDS: \(response.invalidProductIdentifiers)"]))
		}
		
		print("\nreal products:")
		dump(products)
		
		/* first product will get delivered. use when user is purchasing only 1 product */
		if let productRequested = products.first {
			delegate.statusUpdated(status: .paymentRequested)
			
			requestPayment(product: productRequested).then {
				/* payment has been requested */
				self.delegate.statusUpdated(status: .paymentRequested)
				}.catch { error in
					self.delegate.statusUpdated(status: .errorPurchasing)
					self.delegate.errorPurchasing(error: error)
			}
		}
	}
	
	
	
}

//--------------------------------------
// MARK: - Payment Transaction Observer
//--------------------------------------
extension PurchaseManager: SKPaymentTransactionObserver {
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		
		/* send update to delegate about status of the transaction.
		makes sure the transaction is removed from the transaction queue. */
		for transaction in transactions {
			switch transaction.transactionState {
			case .purchased:
				SKPaymentQueue.default().finishTransaction(transaction)
				self.delegate.statusUpdated(status: .paymentReceived)
			case .failed:
				self.delegate.statusUpdated(status: .errorPurchasing)
				self.delegate.errorPurchasing(error: NSError(domain: "Purchasing Error", code: 998, userInfo: [NSLocalizedDescriptionKey: "Transaction failed."]))
				SKPaymentQueue.default().finishTransaction(transaction)
			case .restored: break
			case .purchasing:
				self.delegate.statusUpdated(status: .paymentSent)
			default: break
			}
		}
	}
}











