//
//  KeychainViewController.swift
//  BiometricsExample
//
//  Created by Pawel Rup on 31/08/2019.
//  Copyright © 2019 Pawel Rup. All rights reserved.
//

import UIKit

class KeychainViewController: UIViewController {

	// MARK: - Outlets

	@IBOutlet weak var inputTextField: UITextField!
	@IBOutlet weak var messageLabel: UILabel!

	// MARK: - Actions

	@IBAction func saveAction() {
		if let text = inputTextField.text, !text.isEmpty {
			Keychain.shared.setPassword(text, for: "Password") { [weak self] result in
				if case let .failure(error) = result {
					self?.showAlert(withTitle: "Error", andMessage: error.localizedDescription)
				} else {
					self?.inputTextField.text = nil
				}
			}
		} else {
			showAlert(withTitle: "Oops…", andMessage: "Nothing to store…")
		}
	}

	@IBAction func deleteAction() {
		Keychain.shared.setPassword(nil, for: "Password") { [weak self] result in
			if case let .failure(error) = result {
				self?.showAlert(withTitle: "Error", andMessage: error.localizedDescription)
			}
			self?.inputTextField.text = nil
			self?.messageLabel.text = nil
		}
	}

	@IBAction func fetchAction() {
		Keychain.shared.getPassword(for: "Password") { [weak self] result in
			switch result {
			case let .success(password):
				self?.messageLabel.text = password
			case let .failure(error):
				self?.showAlert(withTitle: "Error", andMessage: error.localizedDescription)
			}
		}
	}

	// MARK: - Alert

	private func showAlert(withTitle title: String?, andMessage message: String?) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true)
	}
}

// MARK: - UITextFieldDelegate
extension KeychainViewController: UITextFieldDelegate {

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
