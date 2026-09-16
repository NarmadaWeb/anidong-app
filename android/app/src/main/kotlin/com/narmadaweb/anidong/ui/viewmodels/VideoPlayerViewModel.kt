package com.narmadaweb.anidong.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.narmadaweb.anidong.data.db.HistoryEntity
import com.narmadaweb.anidong.data.db.ShowDao
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.services.ScrapingService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class VideoPlayerViewModel(
    private val scrapingService: ScrapingService = ScrapingService()
) : ViewModel() {

    private val _episodeDetails = MutableStateFlow<Episode?>(null)
    val episodeDetails: StateFlow<Episode?> = _episodeDetails.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _selectedServerUrl = MutableStateFlow<String?>(null)
    val selectedServerUrl: StateFlow<String?> = _selectedServerUrl.asStateFlow()

    private val _allEpisodes = MutableStateFlow<List<Episode>>(emptyList())
    val allEpisodes: StateFlow<List<Episode>> = _allEpisodes.asStateFlow()

    private val _prevEpisode = MutableStateFlow<Episode?>(null)
    val prevEpisode: StateFlow<Episode?> = _prevEpisode.asStateFlow()

    private val _nextEpisode = MutableStateFlow<Episode?>(null)
    val nextEpisode: StateFlow<Episode?> = _nextEpisode.asStateFlow()

    fun loadEpisode(initialEpisode: Episode, dao: ShowDao) {
        viewModelScope.launch {
            _isLoading.value = true
            _episodeDetails.value = initialEpisode

            val isDonghua = initialEpisode.show?.type == "donghua" || initialEpisode.originalUrl?.contains("anichin") == true
            val detailed = if (isDonghua) {
                scrapingService.getAnichinEpisodeDetails(initialEpisode)
            } else {
                scrapingService.getAnoboyEpisodeDetails(initialEpisode)
            }

            _episodeDetails.value = detailed
            _selectedServerUrl.value = detailed.iframeUrl ?: detailed.videoServers.firstOrNull()?.get("url")
            _isLoading.value = false

            // Record Watch History
            dao.insertHistory(
                HistoryEntity(
                    id = detailed.id,
                    showId = detailed.showId,
                    showTitle = detailed.show?.title ?: detailed.title ?: "Anime",
                    episodeNumber = detailed.episodeNumber,
                    episodeTitle = detailed.title,
                    coverImageUrl = detailed.thumbnailUrl ?: detailed.show?.coverImageUrl,
                    originalUrl = detailed.originalUrl
                )
            )

            // Load Show Episodes if needed
            fetchShowEpisodesIfNeeded(detailed)
        }
    }

    private suspend fun fetchShowEpisodesIfNeeded(currentEp: Episode) {
        val show = currentEp.show
        var eps = show?.episodes
        if (eps.isNullOrEmpty() && show != null && !show.originalUrl.isNullOrEmpty()) {
            val isDonghua = show.type == "donghua" || currentEp.originalUrl?.contains("anichin") == true
            val detailedShow = if (isDonghua) {
                scrapingService.getAnichinShowDetails(show)
            } else {
                scrapingService.getAnoboyShowDetails(show)
            }
            eps = detailedShow.episodes
        }

        if (!eps.isNullOrEmpty()) {
            val sortedList = eps.sortedBy { it.episodeNumber }
            _allEpisodes.value = sortedList

            val currentIndex = sortedList.indexOfFirst {
                it.episodeNumber == currentEp.episodeNumber || it.originalUrl == currentEp.originalUrl
            }

            if (currentIndex != -1) {
                _prevEpisode.value = if (currentIndex > 0) sortedList[currentIndex - 1] else null
                _nextEpisode.value = if (currentIndex < sortedList.size - 1) sortedList[currentIndex + 1] else null
            } else {
                _prevEpisode.value = null
                _nextEpisode.value = null
            }
        }
    }

    fun selectServer(url: String) {
        _selectedServerUrl.value = url
    }
}
