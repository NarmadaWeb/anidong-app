package com.narmadaweb.anidong.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "bookmarks")
data class BookmarkEntity(
    @PrimaryKey val id: Long,
    val title: String,
    val type: String,
    val status: String,
    val coverImageUrl: String?,
    val synopsis: String?,
    val rating: Double?,
    val originalUrl: String?,
    val addedAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "history")
data class HistoryEntity(
    @PrimaryKey val id: Long, // Unique per episode or show
    val showId: Long,
    val showTitle: String,
    val episodeNumber: Int,
    val episodeTitle: String?,
    val coverImageUrl: String?,
    val originalUrl: String?,
    val timestamp: Long = System.currentTimeMillis()
)
