//
//  Transport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/4/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//
// Inspired by: http://robnapier.net/a-mockery-of-protocols

import Foundation
import Localizations

public enum TransportError: LocalizedError, Sendable {
	case noData
    case noURL
	case suspended
	case httpError(status: Int)

	public var errorDescription: String? {
		switch self {
		case .httpError(let status):
			switch status {
			case 400:
				return Localizations.labelTextBadRequest
			case 401:
				return Localizations.labelTextUnauthorized
			case 402:
				return Localizations.labelTextPaymentRequired
			case 403:
				return Localizations.labelTextForbidden
			case 404:
				return Localizations.labelTextNotFound
			case 405:
				return Localizations.labelTextMethodNotAllowed
			case 406:
				return Localizations.labelTextNotAcceptable
			case 407:
				return Localizations.labelTextProxyAuthenticationRequired
			case 408:
				return Localizations.labelTextRequestTimeout
			case 409:
				return Localizations.labelTextConflict
			case 410:
				return Localizations.labelTextGone
			case 411:
				return Localizations.labelTextLengthRequired
			case 412:
				return Localizations.labelTextPreconditionFailed
			case 413:
				return Localizations.labelTextPayloadTooLarge
			case 414:
				return Localizations.labelTextRequestUriTooLong
			case 415:
				return Localizations.labelTextUnsupportedMediaType
			case 416:
				return Localizations.labelTextRequestedRangeNotSatisfiable
			case 417:
				return Localizations.labelTextExpectationFailed
			case 418:
				return Localizations.labelTextIMATeapot
			case 421:
				return Localizations.labelTextMisdirectedRequest
			case 422:
				return Localizations.labelTextUnprocessableEntity
			case 423:
				return Localizations.labelTextLocked
			case 424:
				return Localizations.labelTextFailedDependency
			case 426:
				return Localizations.labelTextUpgradeRequired
			case 428:
				return Localizations.labelTextPreconditionRequired
			case 429:
				return Localizations.labelTextTooManyRequests
			case 431:
				return Localizations.labelTextRequestHeaderFieldsTooLarge
			case 444:
				return Localizations.labelTextConnectionClosedWithoutResponse
			case 451:
				return Localizations.labelTextUnavailableForLegalReasons
			case 499:
				return Localizations.labelTextClientClosedRequest
			case 500:
				return Localizations.labelTextInternalServerError
			case 501:
				return Localizations.labelTextNotImplemented
			case 502:
				return Localizations.labelTextBadGateway
			case 503:
				return Localizations.labelTextServiceUnavailable
			case 504:
				return Localizations.labelTextGatewayTimeout
			case 505:
				return Localizations.labelTextHttpVersionNotSupported
			case 506:
				return Localizations.labelTextVariantAlsoNegotiates
			case 507:
				return Localizations.labelTextInsufficientStorage
			case 508:
				return Localizations.labelTextLoopDetected
			case 510:
				return Localizations.labelTextNotExtended
			case 511:
				return Localizations.labelTextNetworkAuthenticationRequired
			case 599:
				return Localizations.labelTextNetworkConnectTimeoutError
			default:
				let msg = Localizations.labelTextHttpStatus
				return "\(msg) \(status)"
			}
		default:
			return Localizations.labelTextAnUnknownNetworkErrorOccurred
		}
	}

}

nonisolated public protocol Transport: Sendable {

	/// Cancels all pending requests
	func cancelAll()

	/// Sends URLRequest and returns the HTTP headers and the data payload.
	@discardableResult
	func send(request: URLRequest) async throws -> (HTTPURLResponse, Data?)

	/// Sends URLRequest and returns the HTTP headers and the data payload.
	func send(request: URLRequest, completion: @escaping @Sendable (Result<(HTTPURLResponse, Data?), Error>) -> Void)

	/// Sends URLRequest that doesn't require any result information.
	func send(request: URLRequest, method: String) async throws

	/// Sends URLRequest that doesn't require any result information.
	func send(request: URLRequest, method: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void)

	/// Sends URLRequest with a data payload and returns the HTTP headers and the data payload.
	func send(request: URLRequest, method: String, payload: Data) async throws -> (HTTPURLResponse, Data?)

	/// Sends URLRequest with a data payload and returns the HTTP headers and the data payload.
	func send(request: URLRequest, method: String, payload: Data, completion: @escaping @Sendable (Result<(HTTPURLResponse, Data?), Error>) -> Void)

}

nonisolated extension URLSession: Transport {

	public func cancelAll() {
		getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
			for task in dataTasks {
				task.cancel()
			}
			for task in uploadTasks {
				task.cancel()
			}
			for task in downloadTasks {
				task.cancel()
			}
		}
	}

	public func send(request: URLRequest) async throws -> (HTTPURLResponse, Data?) {
		try await withCheckedThrowingContinuation { continuation in
			self.send(request: request) { result in
				continuation.resume(with: result)
			}
		}
	}

	public func send(request: URLRequest, completion: @escaping @Sendable (Result<(HTTPURLResponse, Data?), Error>) -> Void) {
		let task = self.dataTask(with: request) { (data, response, error) in
			DispatchQueue.main.async {
				if let error = error {
					return completion(.failure(error))
				}

				guard let response = response as? HTTPURLResponse, let data = data else {
					return completion(.failure(TransportError.noData))
				}

				switch response.forcedStatusCode {
				case 200...399:
					completion(.success((response, data)))
				default:
					completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
				}
			}
		}
		task.resume()
	}

	public func send(request: URLRequest, method: String) async throws {
		try await withCheckedThrowingContinuation { continuation in
			self.send(request: request, method: method) { result in
				continuation.resume(with: result)
			}
		}
	}

	public func send(request: URLRequest, method: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {

		var sendRequest = request
		sendRequest.httpMethod = method

		let task = self.dataTask(with: sendRequest) { (_, response, error) in
			DispatchQueue.main.async {
				if let error = error {
					return completion(.failure(error))
				}

				guard let response = response as? HTTPURLResponse else {
					return completion(.failure(TransportError.noData))
				}

				switch response.forcedStatusCode {
				case 200...399:
					completion(.success(()))
				default:
					completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
				}
			}
		}
		task.resume()
	}

	public func send(request: URLRequest, method: String, payload: Data) async throws -> (HTTPURLResponse, Data?) {
		try await withCheckedThrowingContinuation { continuation in
			self.send(request: request, method: method, payload: payload) { result in
				continuation.resume(with: result)
			}
		}
	}

	public func send(request: URLRequest, method: String, payload: Data, completion: @escaping @Sendable (Result<(HTTPURLResponse, Data?), Error>) -> Void) {

		var sendRequest = request
		sendRequest.httpMethod = method

		let task = self.uploadTask(with: sendRequest, from: payload) { (data, response, error) in
			DispatchQueue.main.async {
				if let error = error {
					return completion(.failure(error))
				}

				guard let response = response as? HTTPURLResponse, let data = data else {
					return completion(.failure(TransportError.noData))
				}

				switch response.forcedStatusCode {
				case 200...399:
					completion(.success((response, data)))
				default:
					completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
				}

			}
		}
		task.resume()
	}

	public static func webserviceTransport() -> Transport {

		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
		sessionConfiguration.timeoutIntervalForRequest = 60.0
		sessionConfiguration.httpShouldSetCookies = false
		sessionConfiguration.httpCookieAcceptPolicy = .never
		sessionConfiguration.httpMaximumConnectionsPerHost = 2
		sessionConfiguration.httpCookieStorage = nil
		sessionConfiguration.urlCache = nil

		if let userAgentHeaders = UserAgent.headers() {
			sessionConfiguration.httpAdditionalHeaders = userAgentHeaders
		}

		return URLSession(configuration: sessionConfiguration)
	}
}
