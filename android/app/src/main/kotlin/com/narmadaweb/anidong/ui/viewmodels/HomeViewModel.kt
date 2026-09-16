package com.narmadaweb.anidong.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.models.Show
import com.narmadaweb.anidong.data.services.ScrapingService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class ContentMode { DONGHUA, ANIME }

class HomeViewModel(
    private val scrapingService: ScrapingService = ScrapingService()
) : ViewModel() {

    private val _contentMode = MutableStateFlow(ContentMode.DONGHUA)
    val contentMode: StateFlow<ContentMode> = _contentMode.asStateFlow()

    private val _popularShows = MutableStateFlow<List<Show>>(emptyList())
    val popularShows: StateFlow<List<Show>> = _popularShows.asStateFlow()

    private val _recentEpisodes = MutableStateFlow<List<Episode>>(emptyList())
    val recentEpisodes: StateFlow<List<Episode>> = _recentEpisodes.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isLoadingMore = MutableStateFlow(false)
    val isLoadingMore: StateFlow<Boolean> = _isLoadingMore.asStateFlow()

    private var currentPage = 1

    init {
        loadData()
    }

    fun setMode(mode: ContentMode) {
        if (_contentMode.value != mode) {
            _contentMode.value = mode
            currentPage = 1
            loadData()
        }
    }

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            currentPage = 1
            if (_contentMode.value == ContentMode.DONGHUA) {
                val pop = scrapingService.getAnichinPopularToday()
                val rec = scrapingService.getAnichinRecentEpisodes(page = 1)
                _popularShows.value = pop
                _recentEpisodes.value = rec
            } else {
                val pop = scrapingService.getAnoboyPopularToday()
                val rec = scrapingService.getAnoboyRecentEpisodes(page = 1)
                _popularShows.value = pop
                _recentEpisodes.value = rec
            }
            _isLoading.value = false
        }
    }

    fun loadMoreEpisodes() {
        if (_isLoadingMore.value || _isLoading.value) return
        viewModelScope.launch {
            _isLoadingMore.value = true
            val nextPage = currentPage + 1
            val newEpisodes = if (_contentMode.value == ContentMode.DONGHUA) {
                scrapingService.getAnichinRecentEpisodes(page = nextPage)
            } else {
                scrapingService.getAnoboyRecentEpisodes(page = nextPage)
            }
            if (newEpisodes.isNotEmpty()) {
                currentPage = nextPage
                _recentEpisodes.value = _recentEpisodes.value + newEpisodes
            }
            _isLoadingMore.value = false
        }
    }
}
