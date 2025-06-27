/// Модель отзыва.
struct Review: Decodable {
    /// Имя пользователя.
    let first_name: String
    /// Фамилия пользователя.
    let last_name: String
    /// Оценка отзыва.
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    /// Ссылка на аватар пользователя.
    let avatar_url: String
}
