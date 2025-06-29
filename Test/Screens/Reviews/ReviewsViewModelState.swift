/// Модель, хранящая состояние вью модели.

import Foundation
import UIKit

struct ReviewsViewModelState {
    var allItems: [Review] = []
    var displayedItems: [ReviewCellConfig] = []
    var reviewCountCell = ReviewCountCellConfig(reviewCount: NSAttributedString())
    var reviewCount = 0
    var isLoading = false
    var wasLoaded = false
    var currentPage: Int = 0
    let pageSize: Int = 20
}
