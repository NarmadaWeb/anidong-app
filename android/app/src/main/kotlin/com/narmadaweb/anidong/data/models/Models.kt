package com.narmadaweb.anidong.data.models

data class Genre(
    val id: Int = 0,
    val name: String = ""
)

data class Show(
    val id: Long = 0,
    val title: String = "",
    val type: String = "anime", // "anime" or "donghua"
    val status: String = "ongoing",
    val coverImageUrl: String? = null,
    val synopsis: String? = null,
    val rating: Double? = null,
    val originalUrl: String? = null,
    val studio: String? = null,
    val source: String? = null,
    val duration: String? = null,
    val genres: List<Genre> = emptyList(),
    val episodes: List<Episode>? = null
)

data class Episode(
    val id: Long = 0,
    val showId: Long = 0,
    val episodeNumber: Int = 0,
    val title: String? = null,
    val videoUrl: String? = null,
    val iframeUrl: String? = null,
    val videoServers: List<Map<String, String>> = emptyList(),
    val originalUrl: String? = null,
    val downloadLinks: List<Map<String, String>> = emptyList(),
    val thumbnailUrl: String? = null,
    val prevEpisodeUrl: String? = null,
    val nextEpisodeUrl: String? = null,
    val show: Show? = null
)
