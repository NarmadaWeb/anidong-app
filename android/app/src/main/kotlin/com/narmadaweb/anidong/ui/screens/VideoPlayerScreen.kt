package com.narmadaweb.anidong.ui.screens

import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.narmadaweb.anidong.data.db.ShowDao
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.services.ScrapingService
import com.narmadaweb.anidong.ui.theme.CardBackground
import com.narmadaweb.anidong.ui.theme.PrimaryRed
import com.narmadaweb.anidong.ui.viewmodels.VideoPlayerViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VideoPlayerScreen(
    initialEpisode: Episode,
    viewModel: VideoPlayerViewModel,
    dao: ShowDao,
    onBackClick: () -> Unit
) {
    LaunchedEffect(initialEpisode) {
        viewModel.loadEpisode(initialEpisode, dao)
    }

    val episodeDetails by viewModel.episodeDetails.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedServerUrl by viewModel.selectedServerUrl.collectAsState()

    val currentEp = episodeDetails ?: initialEpisode

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(text = currentEp.title ?: "Episode ${currentEp.episodeNumber}", maxLines = 1, overflow = TextOverflow.Ellipsis) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(imageVector = Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Video WebView Player
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(240.dp)
                    .background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                if (selectedServerUrl != null) {
                    AndroidView(
                        factory = { ctx ->
                            WebView(ctx).apply {
                                layoutParams = ViewGroup.LayoutParams(
                                    ViewGroup.LayoutParams.MATCH_PARENT,
                                    ViewGroup.LayoutParams.MATCH_PARENT
                                )
                                settings.javaScriptEnabled = true
                                settings.domStorageEnabled = true
                                webViewClient = object : WebViewClient() {
                                    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                                        return false
                                    }
                                }
                                val referer = if (currentEp.originalUrl?.contains("anichin") == true) ScrapingService.anichinBaseUrl else ScrapingService.anoboyBaseUrl
                                loadUrl(selectedServerUrl!!, mapOf("Referer" to referer))
                            }
                        },
                        update = { webView ->
                            val referer = if (currentEp.originalUrl?.contains("anichin") == true) ScrapingService.anichinBaseUrl else ScrapingService.anoboyBaseUrl
                            if (webView.url != selectedServerUrl) {
                                webView.loadUrl(selectedServerUrl!!, mapOf("Referer" to referer))
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                } else if (isLoading) {
                    CircularProgressIndicator(color = PrimaryRed)
                } else {
                    Text(text = "Pemutar video tidak tersedia", color = Color.White)
                }
            }

            // Video Servers Selector
            val servers = currentEp.videoServers
            if (servers.isNotEmpty()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Pilih Server",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(servers) { server ->
                            val name = server["name"] ?: "Server"
                            val url = server["url"] ?: ""
                            val isSelected = selectedServerUrl == url

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(if (isSelected) PrimaryRed else CardBackground)
                                    .clickable { viewModel.selectServer(url) }
                                    .padding(horizontal = 14.dp, vertical = 8.dp)
                            ) {
                                Text(
                                    text = name,
                                    fontSize = 13.sp,
                                    color = Color.White,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    }
                }
            }

            // Episode Info
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = currentEp.show?.title ?: currentEp.title ?: "",
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Episode ${currentEp.episodeNumber}",
                    color = PrimaryRed,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp
                )
            }
        }
    }
}
