import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Имя пользователя.
    let username: NSAttributedString
    /// Оценка отзыва.
    let rating: UIImage
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Аватар.
    var avatar: UIImage
    /// Фото отзыва.
    var photos: [UIImage]
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.usernameTextLabel.attributedText = username
        cell.ratingImage.image = rating
        cell.setPhotoImages(photos)
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.avatarImage.image = avatar
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?
    
    fileprivate let avatarImage = UIImageView()
    fileprivate let ratingImage = UIImageView()
    fileprivate var photoImages = [UIImageView()]
    fileprivate let usernameTextLabel = UILabel()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        avatarImage.frame = layout.avatarImageFrame
        usernameTextLabel.frame = layout.usernameLabelFrame
        ratingImage.frame = layout.ratingImageFrame
        for i in photoImages.indices {
            photoImages[i].frame = layout.photoImageFrames[i]
        }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
    }
}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImage()
        setupUsernameTextLabel()
        setupRatingImage()
        setupPhotoImages()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
    }
    
    func setupAvatarImage() {
        contentView.addSubview(avatarImage)
        avatarImage.clipsToBounds = true
        avatarImage.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImage.contentMode = .scaleAspectFill
    }
    
    func setupUsernameTextLabel() {
        contentView.addSubview(usernameTextLabel)
    }
    
    func setupRatingImage() {
        contentView.addSubview(ratingImage)
    }
    
    func setupPhotoImages() {
        for i in photoImages.indices {
            contentView.addSubview(photoImages[i])
            photoImages[i].clipsToBounds = true
            photoImages[i].layer.cornerRadius = Layout.photoCornerRadius
            photoImages[i].contentMode = .scaleAspectFill
        }
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.removeTarget(nil, action: nil, for: .allEvents)
        showMoreButton.addTarget(self, action: #selector(showMoreDidTap), for: .touchUpInside)
    }
    
    func setPhotoImages(_ images: [UIImage]) {
        for imageView in photoImages {
            imageView.removeFromSuperview()
        }

        photoImages = images.map { image in
            let imageView = UIImageView(image: image)
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = Layout.photoCornerRadius
            imageView.contentMode = .scaleAspectFill
            contentView.addSubview(imageView)
            return imageView
        }
    }

}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы
    private(set) var avatarImageFrame = CGRect.zero
    private(set) var usernameLabelFrame = CGRect.zero
    private(set) var ratingImageFrame = CGRect.zero
    private(set) var photoImageFrames = Array(repeating: CGRect.zero, count: 5)
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0
    
    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        
        let reviewLOffset = insets.left + Layout.avatarSize.width + avatarToUsernameSpacing
        let width = maxWidth - insets.right - reviewLOffset

        var showShowMoreButton = false
        
        avatarImageFrame = CGRect(
            origin: CGPoint(x: insets.left, y: insets.top),
            size: Layout.avatarSize
        )
        
        usernameLabelFrame = CGRect(
            origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: insets.top),
            size: config.username.boundingRect(width: width).size
        )
        
        ratingImageFrame = CGRect(
            origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: usernameLabelFrame.maxY + usernameToRatingSpacing),
            size: config.rating.size
        )
        
        var maxY = ratingImageFrame.maxY
        
        if !config.photos.isEmpty {
            var maxX = avatarImageFrame.maxX + avatarToUsernameSpacing
            for i in config.photos.indices {
                photoImageFrames[i] = CGRect(
                    origin: CGPoint(x: maxX, y: maxY + ratingToPhotosSpacing),
                    size: Layout.photoSize
                )
                maxX = photoImageFrames[i].maxX + photosSpacing
            }
            maxY = photoImageFrames[0].maxY + photosToTextSpacing
        } else {
            maxY += ratingToTextSpacing
        }

        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: avatarImageFrame.maxX + avatarToUsernameSpacing, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }

}

// MARK: - Actions

private extension ReviewCell {
    
    @objc private func showMoreDidTap() {
        guard let config = config else { return }
        config.onTapShowMore(config.id)
    }
    
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
