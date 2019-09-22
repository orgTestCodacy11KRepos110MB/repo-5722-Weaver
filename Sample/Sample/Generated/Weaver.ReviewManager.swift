/// This file is generated by Weaver 0.12.4
/// DO NOT EDIT!
import API
import Foundation
// MARK: - ReviewManager
protocol ReviewManagerInputDependencyResolver {
    var movieAPI: APIProtocol { get }
}
protocol ReviewManagerDependencyResolver {
    var movieAPI: APIProtocol { get }
    var logger: Logger { get }
}
final class ReviewManagerDependencyContainer: ReviewManagerDependencyResolver {
    let movieAPI: APIProtocol
    private var _logger: Logger?
    var logger: Logger {
        if let value = _logger { return value }
        let value = Logger()
        _logger = value
        return value
    }
    init(injecting dependencies: ReviewManagerInputDependencyResolver) {
        movieAPI = dependencies.movieAPI
        _ = logger
    }
}