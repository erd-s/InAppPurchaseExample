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

/*-------------------------------------------*/

/* link to flow diagram
https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Art/delivering_products_2x.png
*/

protocol PurchaseManagerDelegate {
	func statusUpdated(status: PurchaseManager.PurchaseStatus)
	func errorPurchasing(error: Error)
}


class PurchaseManager: NSObject {
	var productRequest: SKProductsRequest!
	var products: [SKProduct]!
	var payment: SKMutablePayment!
	var delegate: PurchaseManagerDelegate!
	let sharedSecret = "a193c8b409054cce86de22bba0797575"
	
	override init() {
		super.init()
		
		SKPaymentQueue.default().add(self)
	}
	
	/**
	Catch-all for adding a subscription. One-line call in EnterInformationVC.
	*/
	func subscribe(type: SubType) {
		delegate.statusUpdated(status: .requestProduct)
		getProducts(sub: type)
	}
	
	/**
	Get products first.
	
	- parameter sub: `SubType` includes `.yearly` & `.weekly`.
	*/
	func getProducts(sub: SubType) {
		if sub == SubType.yearly {
			productRequest = SKProductsRequest(productIdentifiers: Set(["com.Mouth.InAppPurchasesExample.yearly"]))
		} else {
			productRequest = SKProductsRequest(productIdentifiers: Set(["com.Mouth.InAppPurchasesExample.weekly"]))
		}
		productRequest.delegate = self
		productRequest.start()
	}
	
	
	func requestPayment(product: SKProduct) -> Promise<Void> {
		return Promise { fulfill, reject in
			payment = SKMutablePayment(product: product)
			payment.quantity = 1
			
			if SKPaymentQueue.canMakePayments() {
				SKPaymentQueue.default().add(payment)
			} else {
				reject(NSError(domain: "9999", code: 99, userInfo: nil))
			}
			
			
			fulfill()
		}
	}
	
	func updateUserInfo() {
		/*
		1. track user's subscription type & expiration
		2.
		
		*/
	}
	
	//--------------------------------------
	// MARK: - Support Enums
	//--------------------------------------
	enum SubType {
		case yearly
		case weekly
	}
	
	enum PurchaseStatus {
		case requestProduct
		case requestPayment
		case paymentQueued
		case paymentReceived
		case errorPurchasing
	}
}





extension PurchaseManager: SKProductsRequestDelegate, SKPaymentTransactionObserver {
	func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		products = response.products
		
		if response.invalidProductIdentifiers.count > 0 {
			self.delegate.errorPurchasing(error: NSError(domain: "Purchasing Error", code: 999, userInfo: [NSLocalizedDescriptionKey: "invalid product IDS: \(response.invalidProductIdentifiers)"]))
		}
		
		if let productRequested = products.first {
			delegate.statusUpdated(status: .requestPayment)
			requestPayment(product: productRequested).then {
				self.delegate.statusUpdated(status: .paymentReceived)
				}.catch { error in
					self.delegate.statusUpdated(status: .errorPurchasing)
					self.delegate.errorPurchasing(error: error)
			}
		}
	}
	
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		
		for transaction in transactions {
			switch transaction.transactionState {
			case .purchased:
				SKPaymentQueue.default().finishTransaction(transaction)
				self.delegate.statusUpdated(status: .paymentReceived)
			case .failed: SKPaymentQueue.default().finishTransaction(transaction)
			case .restored: break
			default: break
			}
		}
	}
}










