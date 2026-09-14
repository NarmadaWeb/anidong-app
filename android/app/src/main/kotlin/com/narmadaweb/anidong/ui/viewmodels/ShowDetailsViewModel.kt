package com.narmadaweb.anidong.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.narmadaweb.anidong.data.db.BookmarkEntity
import com.narmadaweb.anidong.data.db.ShowDao
import com.narmadaweb.anidong.data.models.Show
import com.narmadaweb.anidong.data.services.ScrapingService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ShowDetailsViewModel(
    private val scrapingService: ScrapingService = ScrapingService()
) : ViewModel() {

    private val _showDetails = MutableStateFlow<Show?>(null)
    val showDetails: StateFlow<Show?> = _showDetails.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isBookmarked = MutableStateFlow(false)
    val isBookmarked: StateFlow<Boolean> = _isBookmarked.asStateFlow()

    fun loadShow(initialShow: Show, dao: ShowDao) {
        viewModelScope.launch {
            _isLoading.value = true
            _showDetails.value = initialShow
            _isBookmarked.value = dao.isBookmarked(initialShow.id)

            val detailed = if (initialShow.type == "donghua") {
                scrapingService.getAnichinShowDetails(initialShow)
            } else {
                scrapingService.getAnoboyShowDetails(initialShow)
            }

            _showDetails.value = detailed
            _isLoading.value = false
        }
    }

    fun toggleBookmark(dao: ShowDao) {
        val currentShow = _showDetails.value ?: return
        viewModelScope.launch {
            if (_isBookmarked.value) {
                dao.deleteBookmark(currentShow.id)
                _isBookmarked.value = false
            } else {
                dao.insertBookmark(
                    BookmarkEntity(
                        id = currentShow.id,
                        title = currentShow.title,
                        type = currentShow.type,
                        status = currentShow.status,
                        coverImageUrl = currentShow.coverImageUrl,
                        synopsis = currentShow.synopsis,
                        rating = currentShow.rating,
                        originalUrl = currentShow.originalUrl
                    )
                )
                _isBookmarked.value = true
            }
        }
    }
}
