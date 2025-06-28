/// Модель, хранящая состояние вью модели.

import Foundation
import UIKit

struct ReviewsViewModelState {
    var isLoading = false
    var wasLoaded = false
    var items = [any TableCellConfig]()
    var limit = 20
    var offset = 0
    var shouldLoad = true
    var reviewCount = 0
    var reviewCountCell = ReviewCountCellConfig(reviewCount: NSAttributedString())
}
