package com.narmadaweb.anidong

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.google.android.gms.ads.MobileAds
import com.narmadaweb.anidong.data.db.AppDatabase
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.models.Show
import com.narmadaweb.anidong.ui.screens.*
import com.narmadaweb.anidong.ui.theme.AnidongTheme
import com.narmadaweb.anidong.ui.theme.PrimaryRed
import com.narmadaweb.anidong.ui.viewmodels.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MobileAds.initialize(this) {}

        val database = AppDatabase.getDatabase(this)
        val dao = database.showDao()

        setContent {
            AnidongTheme {
                MainAppScreen(dao = dao)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainAppScreen(dao: com.narmadaweb.anidong.data.db.ShowDao) {
    val navController = rememberNavController()
    var selectedItem by remember { mutableIntStateOf(0) }

    var selectedShowForDetails by remember { mutableStateOf<Show?>(null) }
    var selectedEpisodeForPlayer by remember { mutableStateOf<Episode?>(null) }
    var selectedEpisodeForDownload by remember { mutableStateOf<Episode?>(null) }

    val homeViewModel: HomeViewModel = viewModel()
    val showDetailsViewModel: ShowDetailsViewModel = viewModel()
    val videoPlayerViewModel: VideoPlayerViewModel = viewModel()

    val navItems = listOf(
        Triple("Home", Icons.Default.Home, "home"),
        Triple("Jelajah", Icons.Default.Explore, "explore"),
        Triple("Jadwal", Icons.Default.CalendarToday, "schedule"),
        Triple("Daftarku", Icons.Default.Person, "mylist"),
        Triple("Pengaturan", Icons.Default.Settings, "settings")
    )

    Scaffold(
        bottomBar = {
            NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                navItems.forEachIndexed { index, triple ->
                    NavigationBarItem(
                        icon = { Icon(triple.second, contentDescription = triple.first) },
                        label = { Text(triple.first) },
                        selected = selectedItem == index,
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = PrimaryRed,
                            selectedTextColor = PrimaryRed
                        ),
                        onClick = {
                            selectedItem = index
                            navController.navigate(triple.third) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("home") {
                HomeScreen(
                    viewModel = homeViewModel,
                    onShowClick = { show ->
                        selectedShowForDetails = show
                        navController.navigate("show_details")
                    },
                    onEpisodeClick = { episode ->
                        selectedEpisodeForPlayer = episode
                        navController.navigate("video_player")
                    }
                )
            }
            composable("explore") {
                ExploreScreen(
                    onShowClick = { show ->
                        selectedShowForDetails = show
                        navController.navigate("show_details")
                    }
                )
            }
            composable("schedule") {
                ScheduleScreen(
                    onShowClick = { show ->
                        selectedShowForDetails = show
                        navController.navigate("show_details")
                    }
                )
            }
            composable("mylist") {
                MyListScreen(
                    dao = dao,
                    onShowClick = { show ->
                        selectedShowForDetails = show
                        navController.navigate("show_details")
                    }
                )
            }
            composable("settings") {
                SettingsScreen()
            }
            composable("show_details") {
                selectedShowForDetails?.let { show ->
                    ShowDetailsScreen(
                        initialShow = show,
                        viewModel = showDetailsViewModel,
                        dao = dao,
                        onBackClick = { navController.popBackStack() },
                        onEpisodeClick = { ep ->
                            selectedEpisodeForPlayer = ep
                            navController.navigate("video_player")
                        }
                    )
                }
            }
            composable("video_player") {
                selectedEpisodeForPlayer?.let { ep ->
                    VideoPlayerScreen(
                        initialEpisode = ep,
                        viewModel = videoPlayerViewModel,
                        dao = dao,
                        onBackClick = { navController.popBackStack() },
                        onDownloadClick = { downloadEp ->
                            selectedEpisodeForDownload = downloadEp
                            navController.navigate("download")
                        }
                    )
                }
            }
            composable("download") {
                selectedEpisodeForDownload?.let { ep ->
                    DownloadScreen(
                        episode = ep,
                        onBackClick = { navController.popBackStack() }
                    )
                }
            }
        }
    }
}
