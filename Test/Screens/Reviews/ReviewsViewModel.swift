import UIKit
import Foundation

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }
}

// MARK: - Internal

extension ReviewsViewModel {
    
    typealias State = ReviewsViewModelState
    
    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        state.isLoading = true
        onStateChange?(state)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.reviewsProvider.getReviews(offset: self?.state.offset ?? 0) { result in
                DispatchQueue.main.async {
                    self?.gotReviews(result)
                }
            }
        }
    }
}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        
        let group = DispatchGroup()
        
        defer {
            group.notify(queue: .main) { [weak self] in
                guard let self else { return }
                self.state.isLoading = false
                self.state.wasLoaded = true
                self.onStateChange?(self.state)
            }
        }
        
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            state.items += reviews.items.map { makeReviewItem($0, group: group) }
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
            state.reviewCount = reviews.count
            state.reviewCountCell = makeReviewCountItem(reviews.count)
        } catch {
            state.shouldLoad = true
        }
        onStateChange?(state)
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig
    typealias ReviewCountItem = ReviewCountCellConfig

    func makeReviewItem(_ review: Review, group: DispatchGroup?) -> ReviewItem {
        let usernameString = ("\(review.first_name) \(review.last_name)")
        let username = usernameString.attributed(font: .username)
        let rating = ratingRenderer.ratingImage(review.rating)
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        
        var item = ReviewItem(
            username: username,
            rating: rating,
            reviewText: reviewText,
            created: created,
            avatar: UIImage.avatarPic,
            photos: Array(repeating: UIImage.IMG_0001, count: review.photo_urls.count),
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            }
        )
        
        if let url = URL(string: review.avatar_url) {
            group?.enter()
            
            ReviewsPhotoLoader.shared.loadImage(from: url) { [weak self] image in
                defer { group?.leave() }
                
                guard let image else { return }
                
                if let index = self?.state.items.firstIndex(where: {
                    ($0 as? ReviewItem)?.id == item.id
                }) {
                    item.avatar = image
                    self?.state.items[index] = item
                    self?.onStateChange?(self!.state)
                } else {
                    item.avatar = image
                }
            }
        }
        
        for i in review.photo_urls.indices {
            if let url = URL(string: review.photo_urls[i]) {
                group?.enter()
                ReviewsPhotoLoader.shared.loadImage(from: url) { [weak self] image in
                    defer { group?.leave() }
                    
                    guard let image else { return }
                    
                    if let index = self?.state.items.firstIndex(where: {
                        ($0 as? ReviewItem)?.id == item.id
                    }) {
                        item.photos[i] = image
                        self?.state.items[index] = item
                        self?.onStateChange?(self!.state)
                    } else {
                        item.photos[i] = image
                    }
                }
            }
        }
        
        return item
    }
    
    func makeReviewCountItem(_ reviewCount: Int) -> ReviewCountItem {
        let reviewCountString = ("\(reviewCount) отзывов")
        let item = ReviewCountItem(reviewCount: reviewCountString.attributed(font: .reviewCount, color: .reviewCount))
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if state.items.count < state.reviewCount {
            return state.items.count
        } else {
            return state.reviewCount + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == state.reviewCount {
            let config = state.reviewCountCell
            let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
            config.update(cell: cell)
            return cell
        }
        
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == state.reviewCount {
            return state.reviewCountCell.height(with: tableView.bounds.size)
        }
        
        return state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
