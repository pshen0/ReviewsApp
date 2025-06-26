/// Модель, хранящая состояние вью модели.

import Foundation
struct ReviewsViewModelState {

    var items = [any TableCellConfig]()
    var limit = 20
    var offset = 0
    var shouldLoad = true
    var reviewCount = 0
    var reviewCountCell = ReviewCountCellConfig(reviewCount: NSAttributedString())
}
