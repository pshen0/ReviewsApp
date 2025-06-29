import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel
    private let refreshControl = UIRefreshControl()

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
        setupPullToRefresh()
    }
    
    deinit {
        reviewsView.tableView.delegate = nil
        reviewsView.tableView.dataSource = nil
    }
}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsView] state in

            if state.isLoading && !state.wasLoaded {
                reviewsView?.activityIndicator.startAnimating()
                reviewsView?.tableView.isHidden = true
            } else {
                reviewsView?.activityIndicator.stopAnimating()
                reviewsView?.tableView.isHidden = false
            }
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }

            reviewsView?.tableView.reloadData()
        }
    }
    
    func setupPullToRefresh() {
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        reviewsView.tableView.refreshControl = refreshControl
    }

}


// MARK: - Actions

private extension ReviewsViewController {
    
    @objc func refresh() {
        viewModel.refreshReviews()
        reviewsView.tableView.reloadData()
    }
    
}
