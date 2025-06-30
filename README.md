# Тестовое задание ReviewsApp


## Верстка ячейки

Была выполнена минимальная верстка ячейки, добавлена аватарка, имя пользователя и оценка к отзыву.
Соответствующий коммит: Adding avatar, username and rating views
<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/cell1.PNG" width="200">
</div>

---

## Ячейка с количеством отзывов ReviewCountCell

Я добавила новую ячейку ReviewCountCell, которая отображает количество отзывов в конце списка. ReviewCountCell сохраняется в поле ModelState и в DataSource таблицы проверяется, является ли ячейка последней, если это так - отображается ReviewCountCell. Такой подход позволяет не хранить ReviewCountCell в общем массиве ячеек и избежать некорректного появления этой ячейки в момент паггинации.
Соответствующий коммит: 
- Adding ReviewCountCell
- Fixing reviewCountCell label (отображение корректной формы слова в зависимости от количества отзывов)
<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/sumcell.PNG" width="200">
</div>

---

## Утечки памяти

В проекте было обнаружено несколько утечек.

В этом месте происходил цикл ViewModel -> Items -> closure -> ViewModel
Из-за этого ViewModel не мог деинициализироваться и также удерживал классы ReviewsProvider и ReviewsRender.
```
// до
onTapShowMore: showMoreReview 

// после
onTapShowMore: { [weak self] id in
    self?.showMoreReview(with: id)
}

```

Похожая проблемы была в RootViewController:

```
// до
private lazy var rootView = RootView(onTapReviews: openReviews)

// после
private lazy var rootView = RootView{ [weak self] in
    self?.openReviews()
}
```

Также я попробовала воспользоваься инстументами профилирования Links и Memory Graph, они никаких утечек не выявили. В данной реализации проекта все классы успешно деинициализируются.
Соответствующий коммит: Fixing retain cycles

---

## Проблема в UI performance при скролле таблицы

Для решения этой проблемы было достаточно перенести подгрузку отзывов на асинхронную глобальную очередь. 

```
DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    self?.reviewsProvider.getReviews(offset: self?.state.offset ?? 0) { result in
        DispatchQueue.main.async {
            self?.gotReviews(result)
        }
    }
}
```

Соответствующий коммит: Fixing UI-performance bug in scrolling

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/scroll.gif" width="200">
</div>

---

## Реализация действия showMoreButton

Вся UI-логика уже была реализована, я добавила кнопке таргет showMoreDidTap в котором происходит вызов onTapShowMore по нажатию.

Соответствующий коммит: Adding the action to showMoreButton

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/showmore.gif" width="200">
</div>

---

## Аватарка и картинки отзыва

В JSON-файл были добавлены поля avatar_url (ссылка на изображение аватара) и photo_urls (массив ссылок на изображения отзыва от 0 до 5). 
Также добавлен класс ReviewsPhotoLoader для получения картинок из сети (URLSession) и кеширования по ссылке. Загруженные картинки хранятся в File Manager.
Загрузка картинок происходит в makeReviewItem, то есть картинки подгружаются в процессе скроллинга. 

Была адаптирована верстка ячейки ReviewCell для отображения картинок отзыва с корректными отступами для состояний "есть картинки"/"нет картинок".

Соответствующие коммиты: 
- Adding links for users avatars
- Adding loader for avatars with NW
- Adding links for reviews
- Adding photos in ReviewCell

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/cell2.PNG" width="200">
</div>

---

## Индикатор загрузки

Я добавила два новых свойства в ModelState: isLoading и wasLoaded.
isLoading  используется для отслеживания загрузки, wasLoaded показывает, была ли уже первоначальная загрузка. 
Я добавила второе свойство, чтобы индикатор отображался только при переходе на странцу (в первый раз) и не появлялся в процессе скроллинга, так как такой UI выглядит более дерганным.
В процессе пришлось немного пофиксить логику загрузки в получении отзывов. Я добавила DispatchGroup, чтобы отследить когда будут подгружены все картинки первой страницы. 
До этого страница в первый раз (когда FileManager пуст) отображалась с картинками-плейсхолдерами и только потом они обновлялись до нужного состояния. 

Соответствующие коммиты:
- Adding loading indicator
- Fixing loading logic

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/load.gif" width="200">
</div>

## Pull-to-refresh

Добавлен UIRefreshControl, который обновляет данные ModelState и делает релоад таблицы.
Соответствующий коммит: Adding pull-to-refresh
<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/pull.gif" width="200">
</div>

## Изменение логики загрузки данных

Страницы отзывов часто содержат функционал сортировки по разным полям. Однако данная в тесте реализация загрузки данных и паггинации не дает нам возможность сделать сортровку таблицы в любой момент времени, так как данные изначально загружаются неполностью, а сортировка только загруженных ячеек приводит к дерганной анимации перезагрузки таблицы. 
Еще одна проблема - JSON-файл хранит количество записей, не совпадающее с полем count. 

Я изменила JSON-файл и теперь при первой загрузке получаю все его объекты в items, что позволяет мне сразу сортировать записи. Создание item с картинками все также выполняется в режиме паггинации при скролле, не задерживая загрузку страницы, отображаемые ячейки хранятся в displayedItems.

Соответствующий коммит: Changing loading logic

```
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
```

## Сортировка отзывов

Я добавила сортировку отзывов по полям рейтинга. Для этого добавила UIBarButtonItem, который открывает Alert c выбором сортировки.

```
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
```

Теперь getReviews принимает кейс сортировки (на данный момент .noSort, .best, .worst).

Соответствующий коммит: Adding sorting modes

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/sort.gif" width="200">
</div>

## Кастомный LoadIndicator

Теперь при первой загрузке данных отображается кастомный индикатор CustomLoadIndicatorView.

Соответствующий коммит: Adding CALayer animation for indicator

<div style="display: flex; justify-content: space-between;">
    <img src="Screenshots/load.gif" width="200">
</div>

























