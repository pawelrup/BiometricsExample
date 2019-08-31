//
//  Keychain.swift
//  BiometricsExample
//
//  Created by Pawel Rup on 31/08/2019.
//  Copyright © 2019 Pawel Rup. All rights reserved.
//

import Foundation

enum KeychainError: Error {
	case unhandledError(status: OSStatus)
}

class Keychain {

	static let shared = Keychain(serviceIdentifier: Bundle(for: Keychain.self).bundleIdentifier ?? "" + ".Keychain")

	let serviceIdentifier: String

	init(serviceIdentifier: String) {
		self.serviceIdentifier = serviceIdentifier
	}

	/// Sets new value in keychin for given account. Deletes if `password` is `nil`.
	///
	/// - Parameters:
	///   - password: Password to set.
	///   - account: Account for whitch password should be set.
	///   - completion: Closure with result of setting password.
	public func setPassword(_ password: String?, for account: String, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
		if let value = password {
			addPassword(value, for: account, completion)
		} else {
			deletePassword(for: account, completion)
		}
	}

	/// Fetches password from the iOS Keychain. If password does not exist for given account, `Result` will be `nil`.
	///
	/// - Parameter account: Account for whitch password is stored
	/// - Parameter completion: Closure with result of fetching password.
	public func getPassword(for account: String, _ completion: @escaping (Result<String?, Error>) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			var keychainItem = self.createPasswordAttributes(for: account)

			keychainItem[String(kSecReturnData)] = kCFBooleanTrue
			keychainItem[String(kSecReturnAttributes)] = kCFBooleanTrue
			keychainItem[String(kSecUseOperationPrompt)] = "Authenticate to access secret message"
			// Look for a match to the search dictionary in the iOS Keychain.
			var result: CFTypeRef?
			let status = SecItemCopyMatching(keychainItem as CFDictionary, &result)
			DispatchQueue.main.async {
				guard status == errSecSuccess || status == errSecItemNotFound else {
					completion(.failure(KeychainError.unhandledError(status: status)))
					return
				}
				guard let resultsDictionary = result as? [String: Any], let data = resultsDictionary[String(kSecValueData)] as? Data else {
					completion(.success(nil))
					return
				}
				completion(.success(String(data: data, encoding: .utf8)))
			}
		}
	}

	/// Creates an iOS Keychain password attributes.
	///
	/// - Parameter account: Account for whitch password should be set.
	/// - Returns: Keychain password attributes as dictionary
	private func createPasswordAttributes(for account: String) -> [String: Any?] {
		return [
			String(kSecClass): kSecClassGenericPassword,
			String(kSecAttrService): serviceIdentifier,
			String(kSecAttrAccount): account.data(using: .utf8)
		]
	}

	/// Adds password to the iOS Keychain.
	/// Updates if already exists in the iOS Keychain for given account.
	///
	/// - Parameters:
	///   - password: Password to add.
	///   - account: Account for whitch password should be added.
	///   - completion: Closure with result of adding password.
	private func addPassword(_ password: String, for account: String, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
		DispatchQueue.global(qos: .userInitiated).async {
			var attributes = self.createPasswordAttributes(for: account)
			// Add item to the iOS Keychain.
			if let sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, nil) {
				attributes[String(kSecAttrAccessControl)] = sacObject
				attributes[String(kSecUseAuthenticationUI)] = kSecUseAuthenticationUIAllow
			} else {
				attributes[String(kSecAttrAccessible)] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
			}
			attributes[String(kSecValueData)] = password.data(using: .utf8)
			let status = SecItemAdd(attributes as CFDictionary, nil)
			DispatchQueue.main.async {
				// Throw an error if an unexpected status was returned.
				switch status {
				case errSecSuccess:
					break
				case errSecDuplicateItem:
					self.updatePassword(password, for: account)
				default:
					completion?(.failure(KeychainError.unhandledError(status: status)))
				}
			}
		}
	}

	/// Updates password in the iOS Keychain
	///
	/// - Parameters:
	///   - password: Password to update.
	///   - account: Account for whitch password should be updated.
	///   - completion: Closure with result of updating password.
	private func updatePassword(_ password: String, for account: String, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
		DispatchQueue.global(qos: .userInitiated).async {
			var keychainItem = self.createPasswordAttributes(for: account)
			keychainItem[String(kSecUseOperationPrompt)] = "Authenticate to access secret message"
			let attributesToUpdate = [
				String(kSecValueData): password.data(using: .utf8)
			]
			let status = SecItemUpdate(keychainItem as CFDictionary, attributesToUpdate as CFDictionary)
			DispatchQueue.main.async {
				// Throw an error if an unexpected status was returned.
				guard status == errSecSuccess else {
					completion?(.failure(KeychainError.unhandledError(status: status)))
					return
				}
				completion?(.success(()))
			}
		}
	}

	/// Deletes password from the iOS Keychain
	///
	/// - Parameters:
	///   - account: Account for whitch password should be deleted.
	///   - completion: Closure with result of deleting password.
	private func deletePassword(for account: String, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
		DispatchQueue.global(qos: .userInitiated).async {
			let keychainItem = self.createPasswordAttributes(for: account)
			let status = SecItemDelete(keychainItem as CFDictionary)
			DispatchQueue.main.async {
				switch status {
				case errSecSuccess, errSecItemNotFound:
					completion?(.success(()))
				default:
					completion?(.failure(KeychainError.unhandledError(status: status)))
				}
			}
		}
	}
}
