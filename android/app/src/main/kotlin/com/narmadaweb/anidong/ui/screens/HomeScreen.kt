package com.narmadaweb.anidong.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.models.Show
import com.narmadaweb.anidong.ui.theme.CardBackground
import com.narmadaweb.anidong.ui.theme.PrimaryRed
import com.narmadaweb.anidong.ui.viewmodels.ContentMode
import com.narmadaweb.anidong.ui.viewmodels.HomeViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onShowClick: (Show) -> Unit,
    onEpisodeClick: (Episode) -> Unit
) {
    val mode by viewModel.contentMode.collectAsState()
    val popularShows by viewModel.popularShows.collectAsState()
    val recentEpisodes by viewModel.recentEpisodes.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "Ani",
                            fontWeight = FontWeight.Bold,
                            color = PrimaryRed,
                            fontSize = 24.sp
                        )
                        Text(
                            text = "Dong",
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground,
                            fontSize = 24.sp
                        )
                    }
                },
                actions = {
                    ModeSwitch(
                        currentMode = mode,
                        onModeSelected = { viewModel.setMode(it) }
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { innerPadding ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = PrimaryRed)
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
            ) {
                // Popular Carousel / Horizontal Row
                item {
                    Text(
                        text = if (mode == ContentMode.DONGHUA) "Terpopuler Hari Ini" else "Populer Hari Ini",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(16.dp)
                    )
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(popularShows) { show ->
                            PopularShowCard(show = show, onClick = { onShowClick(show) })
                        }
                    }
                }

                // Recent Episodes Section
                item {
                    Text(
                        text = if (mode == ContentMode.DONGHUA) "Rilisan Terbaru (Donghua)" else "Rilisan Terbaru (Anime)",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(16.dp)
                    )
                }

                items(recentEpisodes) { episode ->
                    RecentEpisodeItem(episode = episode, onClick = { onEpisodeClick(episode) })
                }
            }
        }
    }
}

@Composable
fun ModeSwitch(currentMode: ContentMode, onModeSelected: (ContentMode) -> Unit) {
    Row(
        modifier = Modifier
            .padding(end = 12.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(CardBackground)
            .padding(4.dp)
    ) {
        val donghuaBg = if (currentMode == ContentMode.DONGHUA) PrimaryRed else Color.Transparent
        val animeBg = if (currentMode == ContentMode.ANIME) PrimaryRed else Color.Transparent

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(16.dp))
                .background(donghuaBg)
                .clickable { onModeSelected(ContentMode.DONGHUA) }
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text("Donghua", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
        }
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(16.dp))
                .background(animeBg)
                .clickable { onModeSelected(ContentMode.ANIME) }
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text("Anime", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
        }
    }
}

@Composable
fun PopularShowCard(show: Show, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .width(140.dp)
            .height(210.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = CardBackground)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            AsyncImage(
                model = show.coverImageUrl,
                contentDescription = show.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.3f))
            )
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(8.dp)
            ) {
                Text(
                    text = show.title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    color = Color.White
                )
            }
        }
    }
}

@Composable
fun RecentEpisodeItem(episode: Episode, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = CardBackground)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .width(100.dp)
                    .height(65.dp)
                    .clip(RoundedCornerShape(8.dp))
            ) {
                AsyncImage(
                    model = episode.thumbnailUrl ?: episode.show?.coverImageUrl,
                    contentDescription = episode.title,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
                Icon(
                    imageVector = Icons.Default.PlayArrow,
                    contentDescription = "Play",
                    tint = Color.White,
                    modifier = Modifier
                        .align(Alignment.Center)
                        .size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = episode.show?.title ?: episode.title ?: "",
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Episode ${episode.episodeNumber}",
                    color = PrimaryRed,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}
