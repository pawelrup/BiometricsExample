//
//  LocalAuthenticationViewController.swift
//  BiometricsExample
//
//  Created by Pawel Rup on 31/08/2019.
//  Copyright © 2019 Pawel Rup. All rights reserved.
//

import UIKit
import LocalAuthentication

class LocalAuthenticationViewController: UIViewController {

	// MARK: - Outlets

	@IBOutlet weak var secretTextView: UITextView!

	// MARK: - Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
			self?.secretTextView.contentInset.bottom = 0
		}
		notificationCenter.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] notification in
			if let frame = self?.getKeyboardFrame(from: notification) {
				if #available(iOS 11.0, *) {
					self?.secretTextView.contentInset.bottom = frame.height - (self?.view.safeAreaInsets.bottom ?? 0)
				} else {
					self?.secretTextView.contentInset.bottom = frame.height
				}
			}
		}
		notificationCenter.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] notification in
			self?.secretTextView.text = nil
		}
	}

	// MARK: - Actions

	@IBAction func authenticateTapped() {
		authenticate { [weak self] result in
			if case let .failure(error) = result {
				print(String(describing: error))
				let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
				ac.addAction(UIAlertAction(title: "OK", style: .default))
				self?.present(ac, animated: true)
			} else {
				self?.secretTextView.text = "woohoo"
			}
		}
	}

	// MARK: - Other functions

	private func authenticate(_ completion: @escaping (Result<Void, Error>) -> Void) {
		let context = LAContext()
		var error: NSError?
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			let reason = "Identify yourself!"
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
				success, authenticationError in
				DispatchQueue.main.async {
					if let error = error, !success {
						completion(.failure(error))
					} else {
						completion(.success(()))
					}
				}
			}
		} else if let error = error {
			completion(.failure(error as Error))
		}
	}

	private func getKeyboardFrame(from notification: Notification) -> CGRect? {
		guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
			return nil
		}
		return view.convert(keyboardFrame, to: view.window)
	}
}
