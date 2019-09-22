/// This file is generated by Weaver 0.12.4
/// DO NOT EDIT!
import API
import Foundation
import UIKit
// MARK: - MovieViewController
protocol MovieViewControllerInputDependencyResolver {
    var movieManager: MovieManaging { get }
    var imageManager: ImageManaging { get }
    var reviewManager: ReviewManaging { get }
}
protocol MovieViewControllerDependencyResolver {
    var movieID: UInt { get }
    var title: String { get }
    var movieManager: MovieManaging { get }
    var imageManager: ImageManaging { get }
    var logger: Logger { get }
    func reviewController(movieID: UInt) -> WSReviewViewController
}
final class MovieViewControllerDependencyContainer: MovieViewControllerDependencyResolver {
    let movieID: UInt
    let title: String
    let movieManager: MovieManaging
    let imageManager: ImageManaging
    let reviewManager: ReviewManaging
    private var _logger: Logger?
    var logger: Logger {
        if let value = _logger { return value }
        let value = Logger()
        _logger = value
        return value
    }
    private var _reviewController: WSReviewViewController?
    func reviewController(movieID: UInt) -> WSReviewViewController {
        if let value = _reviewController { return value }
        let dependencies = WSReviewViewControllerDependencyContainer(injecting: self, movieID: movieID)
        let value = WSReviewViewController(injecting: dependencies)
        _reviewController = value
        return value
    }
    init(injecting dependencies: MovieViewControllerInputDependencyResolver, movieID: UInt, title: String) {
        self.movieID = movieID
        self.title = title
        movieManager = dependencies.movieManager
        imageManager = dependencies.imageManager
        reviewManager = dependencies.reviewManager
        _ = logger
        _ = reviewController(movieID: movieID)
    }
}
extension MovieViewControllerDependencyContainer: WSReviewViewControllerInputDependencyResolver {}