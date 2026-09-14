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
        }
    }

    fun selectServer(url: String) {
        _selectedServerUrl.value = url
    }
}
