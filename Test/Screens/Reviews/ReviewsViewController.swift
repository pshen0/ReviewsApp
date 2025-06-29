import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel
    private let refreshControl = UIRefreshControl()
    private let sortingModesAlert = UIAlertController(
        title: nil,
        message: nil,
        preferredStyle: .actionSheet
    )

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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.and.down.and.sparkles"), style: .plain, target: self, action: #selector(presentSortingModes))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupPullToRefresh()
        setupSortingModesAlert()
        viewModel.getReviews(sortingMode: .noSort)
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
    
    func setupSortingModesAlert() {
        sortingModesAlert.addAction(UIAlertAction(title: "С высокой оценкой", style: .default) { [weak self] _ in
            self?.viewModel.getReviews(sortingMode: .best)
            self?.reviewsView.tableView.reloadData()
        })

        sortingModesAlert.addAction(UIAlertAction(title: "С низкой оценкой", style: .default) { [weak self] _ in
            self?.viewModel.getReviews(sortingMode: .worst)
            self?.reviewsView.tableView.reloadData()
        })

        sortingModesAlert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
    }

}


// MARK: - Actions

private extension ReviewsViewController {
    
    @objc func refresh() {
        viewModel.refreshReviews()
        reviewsView.tableView.reloadData()
    }
    
    @objc func presentSortingModes() {
        present(sortingModesAlert, animated: true, completion: nil)
    }
    
}
