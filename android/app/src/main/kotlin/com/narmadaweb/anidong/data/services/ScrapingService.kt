package com.narmadaweb.anidong.data.services

import android.util.Base64
import com.narmadaweb.anidong.data.models.Episode
import com.narmadaweb.anidong.data.models.Genre
import com.narmadaweb.anidong.data.models.Show
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import java.util.concurrent.TimeUnit
import java.util.regex.Pattern

class ScrapingService(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()
) {
    companion object {
        var anoboyBaseUrl = "https://ww1.anoboy.boo"
        var anichinBaseUrl = "https://anichin.moe"

        const val DEFAULT_USER_AGENT =
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

        fun getAnichinHeaders(): Map<String, String> = mapOf(
            "User-Agent" to DEFAULT_USER_AGENT,
            "Accept" to "*/*",
            "Accept-Language" to "en-US,en;q=0.9",
            "Referer" to anichinBaseUrl
        )

        fun getAnoboyHeaders(): Map<String, String> = mapOf(
            "User-Agent" to DEFAULT_USER_AGENT,
            "Accept" to "*/*",
            "Accept-Language" to "en-US,en;q=0.9",
            "Referer" to anoboyBaseUrl
        )
    }

    private fun normalizeUrl(url: String?, baseUrl: String): String {
        if (url.isNullOrEmpty() || url == "#" || url == "none") return ""
        if (url.startsWith("http")) return url
        if (url.startsWith("//")) return "https:$url"
        if (url.startsWith("/")) {
            val base = if (baseUrl.endsWith("/")) baseUrl.dropLast(1) else baseUrl
            return "$base$url"
        }
        val base = if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
        return "$base$url"
    }

    private fun extractImageUrl(imgElement: Element?): String {
        if (imgElement == null) return ""
        val thumb = imgElement.attr("data-src").ifEmpty {
            imgElement.attr("data-lazy-src").ifEmpty {
                imgElement.attr("src")
            }
        }
        return normalizeUrl(thumb, anoboyBaseUrl)
    }

    private fun fetchDocument(url: String, headers: Map<String, String>): Document? {
        val requestBuilder = Request.Builder().url(url)
        headers.forEach { (k, v) -> requestBuilder.addHeader(k, v) }
        val response = client.newCall(requestBuilder.build()).execute()
        if (!response.isSuccessful) return null
        val bodyStr = response.body?.string() ?: return null
        return Jsoup.parse(bodyStr, url)
    }

    suspend fun getAnoboyRecentEpisodes(page: Int = 1): List<Episode> = withContext(Dispatchers.IO) {
        try {
            val url = if (page > 1) "$anoboyBaseUrl/page/$page/" else anoboyBaseUrl
            val doc = fetchDocument(url, getAnoboyHeaders()) ?: return@withContext emptyList()
            val episodes = mutableListOf<Episode>()

            val elements = doc.select(".home_index a[rel=bookmark]")
            for (element in elements) {
                if (element.select(".amv").isEmpty()) continue

                val title = element.attr("title").ifEmpty {
                    element.select("h3.ibox1").text().trim()
                }
                val href = element.attr("href")
                val imgElement = element.selectFirst("img")

                if (title.isNotEmpty() && href.isNotEmpty()) {
                    val thumb = extractImageUrl(imgElement)
                    var epNum = 0
                    val matcher = Pattern.compile("(?:Episode|Ep)\\s+(\\d+)", Pattern.CASE_INSENSITIVE).matcher(title)
                    if (matcher.find()) {
                        epNum = matcher.group(1)?.toIntOrNull() ?: 0
                    }

                    val absoluteUrl = normalizeUrl(href, anoboyBaseUrl)
                    val showTitle = title.split(" Episode")[0].split(" Ep ")[0]

                    episodes.add(
                        Episode(
                            id = absoluteUrl.hashCode().toLong(),
                            showId = showTitle.hashCode().toLong(),
                            episodeNumber = epNum,
                            title = title,
                            thumbnailUrl = thumb,
                            originalUrl = absoluteUrl,
                            show = Show(
                                id = showTitle.hashCode().toLong(),
                                title = showTitle,
                                type = "anime",
                                status = "ongoing",
                                coverImageUrl = thumb
                            )
                        )
                    )
                }
            }
            episodes
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun findAnichinListupd(document: Document, keywords: List<String>): Element? {
        val blocks = document.select(".bixbox")
        for (b in blocks) {
            val headings = b.select("h2, h3, h4, div, span")
            for (h in headings) {
                val text = h.text().trim().lowercase()
                if (keywords.any { text.contains(it) }) {
                    val listupd = b.selectFirst(".listupd")
                    if (listupd != null) return listupd
                }
            }
        }

        val listupds = document.select(".listupd")
        for (listupd in listupds) {
            val prev = listupd.previousElementSibling()
            if (prev != null) {
                val text = prev.text().trim().lowercase()
                if (keywords.any { text.contains(it) }) {
                    return listupd
                }
            }
        }
        return null
    }

    suspend fun getAnichinRecentEpisodes(page: Int = 1): List<Episode> = withContext(Dispatchers.IO) {
        try {
            val url = if (page > 1) "$anichinBaseUrl/page/$page/" else anichinBaseUrl
            val doc = fetchDocument(url, getAnichinHeaders()) ?: return@withContext emptyList()
            val episodes = mutableListOf<Episode>()

            val listupds = doc.select(".listupd")
            val latestSection = findAnichinListupd(doc, listOf("rilisan terbaru", "latest release"))
                ?: (if (listupds.size > 1) listupds[1] else listupds.firstOrNull()) ?: return@withContext emptyList()

            val elements = latestSection.select(".bs")
            for (element in elements) {
                val titleElement = element.selectFirst(".tt")
                val linkElement = element.selectFirst("a")
                val imgElement = element.selectFirst("img")
                val epElement = element.selectFirst(".epx")

                if (titleElement != null && linkElement != null) {
                    val h2 = titleElement.selectFirst("h2")
                    val rawTitle = h2?.text()?.trim() ?: titleElement.text().trim()
                    val rawUrl = linkElement.attr("href")
                    val fullUrl = normalizeUrl(rawUrl, anichinBaseUrl)
                    val thumb = imgElement?.attr("src") ?: ""
                    val epText = epElement?.text()?.trim() ?: ""

                    if (epText.contains("Ep 0") && !epText.contains("Ep 01")) continue

                    var epNum = 0
                    val matcher = Pattern.compile("(\\d+)").matcher(epText)
                    if (matcher.find()) {
                        epNum = matcher.group(1)?.toIntOrNull() ?: 0
                    }

                    val showTitle = rawTitle.split(" Episode")[0].split(" Ep ")[0]
                    val absoluteUrl = normalizeUrl(fullUrl, anichinBaseUrl)

                    episodes.add(
                        Episode(
                            id = absoluteUrl.hashCode().toLong(),
                            showId = showTitle.hashCode().toLong(),
                            episodeNumber = epNum,
                            title = showTitle,
                            thumbnailUrl = thumb,
                            originalUrl = absoluteUrl,
                            show = Show(
                                id = showTitle.hashCode().toLong(),
                                title = showTitle,
                                type = "donghua",
                                status = "ongoing"
                            )
                        )
                    )
                }
            }
            episodes
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getAnoboyPopularToday(): List<Show> = withContext(Dispatchers.IO) {
        try {
            val doc = fetchDocument(anoboyBaseUrl, getAnoboyHeaders()) ?: return@withContext emptyList()
            val shows = mutableListOf<Show>()

            val containers = doc.select(".side_home")
            var popularContainer: Element? = null

            for (container in containers) {
                val header = container.selectFirst("h2.jdl")
                if (header != null) {
                    val text = header.text().lowercase()
                    if (text.contains("baru ditambahkan") || text.contains("paling banyak dilihat")) {
                        popularContainer = container
                        break
                    }
                }
            }

            val elements = (popularContainer ?: doc).select("a[rel=bookmark]")
            val seenTitles = mutableSetOf<String>()

            for (element in elements) {
                if (popularContainer != null && !element.parents().contains(popularContainer)) continue

                val title = element.attr("title").ifEmpty { element.select("h3.ibox").text().trim() }
                val href = element.attr("href")
                val imgElement = element.selectFirst("img")

                if (title.isNotEmpty() && href.isNotEmpty()) {
                    val thumb = extractImageUrl(imgElement)
                    val absoluteUrl = normalizeUrl(href, anoboyBaseUrl)
                    val cleanTitle = title.split(" Episode")[0].split(" Ep ")[0]

                    if (seenTitles.add(cleanTitle)) {
                        shows.add(
                            Show(
                                id = absoluteUrl.hashCode().toLong(),
                                title = cleanTitle,
                                type = "anime",
                                status = "ongoing",
                                coverImageUrl = thumb,
                                originalUrl = absoluteUrl
                            )
                        )
                    }
                }
            }
            shows
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getAnichinPopularToday(): List<Show> = withContext(Dispatchers.IO) {
        try {
            val doc = fetchDocument(anichinBaseUrl, getAnichinHeaders()) ?: return@withContext emptyList()
            val shows = mutableListOf<Show>()

            val popularSection = findAnichinListupd(doc, listOf("terpopuler hari ini", "popular today", "terpopuler"))
                ?: doc.selectFirst(".listupd") ?: return@withContext emptyList()

            val elements = popularSection.select(".bs")
            for (element in elements) {
                val titleElement = element.selectFirst(".tt")
                val linkElement = element.selectFirst("a")
                val imgElement = element.selectFirst("img")

                if (titleElement != null && linkElement != null) {
                    val h2 = titleElement.selectFirst("h2")
                    val title = h2?.text()?.trim() ?: titleElement.text().trim()
                    val rawUrl = linkElement.attr("href")
                    val url = normalizeUrl(rawUrl, anichinBaseUrl)
                    val thumb = imgElement?.attr("src") ?: ""

                    var status = "ongoing"
                    val statusEl = element.selectFirst(".status") ?: element.selectFirst(".sb") ?: element.selectFirst(".limit .bt")
                    if (statusEl != null) {
                        val text = statusEl.text().trim().lowercase()
                        if (text.contains("completed") || text.contains("end") || text.contains("tamat")) {
                            status = "completed"
                        }
                    }

                    shows.add(
                        Show(
                            id = url.hashCode().toLong(),
                            title = title.split(" Episode")[0].split(" Ep ")[0],
                            type = "donghua",
                            status = status,
                            coverImageUrl = thumb,
                            originalUrl = normalizeUrl(url, anichinBaseUrl)
                        )
                    )
                }
            }
            shows
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getAnichinShowDetails(show: Show): Show = withContext(Dispatchers.IO) {
        val safeUrl = show.originalUrl ?: return@withContext show
        try {
            val doc = fetchDocument(normalizeUrl(safeUrl, anichinBaseUrl), getAnichinHeaders()) ?: return@withContext show
            parseAnichinShowDetailsFromDoc(doc, show)
        } catch (e: Exception) {
            show
        }
    }

    fun parseAnichinShowDetailsFromDoc(doc: Document, show: Show): Show {
        var extractedRating: Double? = null
        val metaContent = doc.selectFirst("meta[itemprop=ratingValue]")?.attr("content")
        if (metaContent != null) {
            extractedRating = metaContent.toDoubleOrNull()
        } else {
            val strongText = doc.selectFirst(".rating strong")?.text()?.trim()
            if (strongText != null) {
                val matcher = Pattern.compile("Rating\\s+(\\d+\\.?\\d*)").matcher(strongText)
                if (matcher.find()) {
                    extractedRating = matcher.group(1)?.toDoubleOrNull()
                }
            }
        }

        var synopsis: String? = null
        val synEl = doc.selectFirst(".entry-content[itemprop=description] p")
            ?: doc.selectFirst(".entry-content p")
            ?: doc.selectFirst(".desc")

        if (synEl != null) {
            synopsis = synEl.text().trim()
        } else {
            val content = doc.selectFirst(".entry-content")
            if (content != null) {
                val paragraphs = content.select("p")
                var longest = ""
                for (p in paragraphs) {
                    val text = p.text().trim()
                    if (text.length > longest.length) {
                        longest = text
                    }
                }
                if (longest.isNotEmpty()) synopsis = longest
            }
        }

        var coverImage = show.coverImageUrl
        val imgEl = doc.selectFirst(".thumb img")
            ?: doc.selectFirst(".ts-post-image")
            ?: doc.selectFirst(".wp-post-image")
            ?: doc.selectFirst("div[itemprop=image] img")

        if (imgEl != null) {
            val extracted = extractImageUrl(imgEl)
            if (extracted.isNotEmpty()) coverImage = extracted
        }

        val allEpisodes = mutableListOf<Episode>()
        var epElements = doc.select(".eplister li a")
        if (epElements.isEmpty()) epElements = doc.select(".lstep li a")
        if (epElements.isEmpty()) epElements = doc.select(".episodelist li a")

        for (epEl in epElements) {
            val rawUrl = epEl.attr("href")
            val url = normalizeUrl(rawUrl, anichinBaseUrl)
            val numText = epEl.selectFirst(".epl-num")?.text()?.trim() ?: ""
            val title = epEl.selectFirst(".epl-title")?.text()?.trim() ?: ""

            var thumb = epEl.selectFirst("img")?.attr("src")
            if (thumb.isNullOrEmpty()) thumb = epEl.selectFirst("img")?.attr("data-src")

            if (url.isNotEmpty()) {
                val absoluteUrl = normalizeUrl(url, anichinBaseUrl)
                allEpisodes.add(
                    Episode(
                        id = absoluteUrl.hashCode().toLong(),
                        showId = show.id,
                        episodeNumber = numText.toIntOrNull() ?: 0,
                        title = title,
                        originalUrl = url,
                        thumbnailUrl = thumb,
                        show = show
                    )
                )
            }
        }

        return show.copy(
            rating = extractedRating,
            synopsis = synopsis,
            coverImageUrl = coverImage,
            episodes = if (allEpisodes.isNotEmpty()) allEpisodes else null
        )
    }

    suspend fun getAnoboyShowDetails(show: Show): Show = withContext(Dispatchers.IO) {
        val url = show.originalUrl ?: return@withContext show
        try {
            val doc = fetchDocument(url, getAnoboyHeaders()) ?: return@withContext show
            parseAnoboyShowDetailsFromDoc(doc, show)
        } catch (e: Exception) {
            show
        }
    }

    fun parseAnoboyShowDetailsFromDoc(doc: Document, show: Show): Show {
        val allEpisodes = parseAnoboyEpisodesFromDoc(doc, show.id, show.title, show).toMutableList()

        allEpisodes.sortWith(Comparator { a, b ->
            fun getSeason(title: String?): Int {
                if (title == null) return 0
                val matcher = Pattern.compile("(?:Season|S)\\s*(\\d+)", Pattern.CASE_INSENSITIVE).matcher(title)
                return if (matcher.find()) matcher.group(1)?.toIntOrNull() ?: 0 else 0
            }
            val seasonA = getSeason(a.title)
            val seasonB = getSeason(b.title)
            if (seasonA != seasonB) seasonA.compareTo(seasonB) else a.episodeNumber.compareTo(b.episodeNumber)
        })

        var extractedRating: Double? = null
        val scoreElement = doc.selectFirst("#score")
        if (scoreElement != null) {
            extractedRating = scoreElement.text().trim().toDoubleOrNull()
        }

        var studio: String? = null
        var source: String? = null
        var duration: String? = null
        val genres = mutableListOf<Genre>()

        val rows = doc.select(".entry-content table tr, .post-body table tr")
        if (rows.isNotEmpty()) {
            for (row in rows) {
                val cols = row.select("td")
                if (cols.size >= 2) {
                    val key = cols[0].text().trim().lowercase()
                    val value = cols.last()?.text()?.trim() ?: ""

                    if (key.contains("studio")) studio = value
                    else if (key.contains("source")) source = value
                    else if (key.contains("durasi") || key.contains("duration")) duration = value
                    else if (key.contains("genre")) {
                        value.split(",").map { it.trim() }.filter { it.isNotEmpty() }.forEach { g ->
                            genres.add(Genre(id = g.hashCode(), name = g))
                        }
                    } else if ((key.contains("skor") || key.contains("score")) && extractedRating == null) {
                        extractedRating = value.toDoubleOrNull()
                    }
                }
            }
        }

        var synopsis: String? = null
        val contentEl = doc.selectFirst(".entry-content, .post-body")
        if (contentEl != null) {
            val paragraphs = contentEl.select("p")
            for (p in paragraphs) {
                val text = p.text().trim()
                if (text.lowercase().contains("download") || text.lowercase().contains("mirror") || text.contains(":")) continue
                if (text.length > 50) {
                    synopsis = if (synopsis == null) text else "$synopsis\n\n$text"
                }
            }
            if (synopsis == null) synopsis = contentEl.text().trim()
            if (synopsis.length > 500) synopsis = "${synopsis.substring(0, 500)}..."
        }

        var coverImage = show.coverImageUrl
        if (coverImage.isNullOrEmpty()) {
            val imgEl = doc.selectFirst(".entry-content img, .post-body img")
            coverImage = extractImageUrl(imgEl)
        }

        return show.copy(
            rating = extractedRating,
            synopsis = synopsis,
            coverImageUrl = coverImage,
            studio = studio,
            source = source,
            duration = duration,
            genres = if (genres.isNotEmpty()) genres else emptyList(),
            episodes = if (allEpisodes.isNotEmpty()) allEpisodes else null
        )
    }

    private fun parseAnoboyEpisodesFromDoc(doc: Document, showId: Long, showTitle: String?, show: Show?): List<Episode> {
        val eps = mutableListOf<Episode>()
        val epLinks = mutableListOf<Element>()

        val listContainers = doc.select(".lcp_catlist")
        val contentContainers = doc.select(".entry-content, .post-body, .episodelist, #content, .singlelink, .sisi")

        for (c in listContainers) epLinks.addAll(c.select("a"))
        for (c in contentContainers) epLinks.addAll(c.select("a"))
        if (epLinks.isEmpty()) epLinks.addAll(doc.select("a[rel=bookmark]"))

        val seenUrls = mutableSetOf<String>()

        for (link in epLinks) {
            val title = link.attr("title").ifEmpty { link.text().trim() }
            var url = link.attr("href")

            if (url.isEmpty() || url.contains("#") || url.contains("facebook") || url.contains("twitter")) continue

            val fullUrl = normalizeUrl(url, anoboyBaseUrl)
            if (seenUrls.contains(fullUrl)) continue

            val containsEp = title.lowercase().contains("episode") || title.lowercase().contains("ep ") || title.lowercase().contains("download")
            if (containsEp) {
                var epNum = 0
                val matcher = Pattern.compile("(?:Episode|Ep|Part|Cour)\\s+(\\d+)", Pattern.CASE_INSENSITIVE).matcher(title)
                if (matcher.find()) {
                    epNum = matcher.group(1)?.toIntOrNull() ?: 0
                }

                seenUrls.add(fullUrl)
                eps.add(
                    Episode(
                        id = fullUrl.hashCode().toLong(),
                        showId = showId,
                        episodeNumber = epNum,
                        title = title,
                        originalUrl = fullUrl,
                        show = show
                    )
                )
            }
        }
        return eps
    }

    suspend fun resolveAnichinProxyUrl(originalUrl: String): String = withContext(Dispatchers.IO) {
        if (!originalUrl.contains("anichin.moe/stream/") && !originalUrl.contains("anichin-player.web.id")) {
            return@withContext originalUrl
        }
        try {
            val doc = fetchDocument(originalUrl, getAnichinHeaders()) ?: return@withContext originalUrl
            val iframe = doc.selectFirst("iframe")
            val src = iframe?.attr("src")
            if (!src.isNullOrEmpty()) {
                val absSrc = normalizeUrl(src, anichinBaseUrl)
                if (absSrc.contains("anichin.moe/stream/") || absSrc.contains("anichin-player.web.id")) {
                    return@withContext resolveAnichinProxyUrl(absSrc)
                }
                return@withContext absSrc
            }
        } catch (e: Exception) { }
        originalUrl
    }

    fun extractAnichinServers(doc: Document): List<Map<String, String>> {
        val videoServers = mutableListOf<Map<String, String>>()

        var iframeElement = doc.selectFirst("iframe[src*=anichin.stream]")
            ?: doc.selectFirst(".video-content iframe")
            ?: doc.selectFirst("iframe")

        val primaryIframe = iframeElement?.attr("src")
        if (!primaryIframe.isNullOrEmpty()) {
            videoServers.add(mapOf("name" to "Primary Server", "url" to normalizeUrl(primaryIframe, anichinBaseUrl)))
        }

        val serverElements = doc.select(".mirror option")
        for (opt in serverElements) {
            var url = opt.attr("value")
            val name = opt.text().trim()

            if (url.isNotEmpty()) {
                if (url.startsWith("PG")) {
                    try {
                        val decodedBytes = Base64.decode(url, Base64.DEFAULT)
                        val decoded = String(decodedBytes, Charsets.UTF_8)
                        val matcher = Pattern.compile("src=[\"'](.*?)[\"']", Pattern.CASE_INSENSITIVE).matcher(decoded)
                        if (matcher.find()) {
                            url = matcher.group(1) ?: url
                        }
                    } catch (e: Exception) { }
                }
                videoServers.add(mapOf("name" to name.ifEmpty { "Server ${videoServers.size + 1}" }, "url" to normalizeUrl(url, anichinBaseUrl)))
            }
        }
        return videoServers
    }

    suspend fun getAnichinEpisodeDetails(episode: Episode): Episode = withContext(Dispatchers.IO) {
        val safeUrl = episode.originalUrl ?: return@withContext episode
        try {
            val doc = fetchDocument(normalizeUrl(safeUrl, anichinBaseUrl), getAnichinHeaders()) ?: return@withContext episode

            val videoServers = extractAnichinServers(doc).map { server ->
                val resolved = resolveAnichinProxyUrl(server["url"] ?: "")
                mapOf("name" to (server["name"] ?: "Server"), "url" to resolved)
            }

            val downloadLinks = mutableListOf<Map<String, String>>()
            val dlWrappers = doc.select(".mctnx")
            if (dlWrappers.isNotEmpty()) {
                for (wrapper in dlWrappers) {
                    val resLabel = wrapper.selectFirst(".sorattl")?.text()?.trim() ?: "Download"
                    for (link in wrapper.select("a")) {
                        val provider = link.text().trim()
                        val href = link.attr("href")
                        if (href.isNotEmpty() && !href.startsWith("#")) {
                            downloadLinks.add(mapOf("name" to "$resLabel - $provider", "url" to normalizeUrl(href, anichinBaseUrl)))
                        }
                    }
                }
            }

            episode.copy(
                iframeUrl = videoServers.firstOrNull()?.get("url"),
                videoServers = videoServers,
                downloadLinks = downloadLinks
            )
        } catch (e: Exception) {
            episode
        }
    }

    suspend fun getAnoboyEpisodeDetails(episode: Episode): Episode = withContext(Dispatchers.IO) {
        val url = episode.originalUrl ?: return@withContext episode
        try {
            val doc = fetchDocument(url, getAnoboyHeaders()) ?: return@withContext episode
            val videoServers = mutableListOf<Map<String, String>>()

            val iframe = doc.selectFirst("iframe#mediaplayer") ?: doc.selectFirst("iframe")
            if (iframe != null) {
                val src = iframe.attr("src")
                if (src.isNotEmpty()) {
                    videoServers.add(mapOf("name" to "Primary Server", "url" to normalizeUrl(src, anoboyBaseUrl)))
                }
            }

            val mirrors = doc.select(".vmiror a")
            for (m in mirrors) {
                val link = m.attr("data-video").ifEmpty { m.attr("href") }
                if (link.isNotEmpty() && link != "#") {
                    videoServers.add(mapOf("name" to m.text().trim().ifEmpty { "Mirror Server" }, "url" to normalizeUrl(link, anoboyBaseUrl)))
                }
            }

            episode.copy(
                iframeUrl = videoServers.firstOrNull()?.get("url"),
                videoServers = videoServers
            )
        } catch (e: Exception) {
            episode
        }
    }

    suspend fun searchAnoboy(query: String): List<Show> = withContext(Dispatchers.IO) {
        try {
            val doc = fetchDocument("$anoboyBaseUrl/?s=${query}", getAnoboyHeaders()) ?: return@withContext emptyList()
            val shows = mutableListOf<Show>()
            for (el in doc.select("a[rel=bookmark]")) {
                val title = el.attr("title").ifEmpty { el.select("h3.ibox1").text().trim() }
                val href = el.attr("href")
                if (title.isNotEmpty() && href.isNotEmpty()) {
                    shows.add(
                        Show(
                            id = href.hashCode().toLong(),
                            title = title.split(" Episode")[0].split(" Ep ")[0],
                            type = "anime",
                            coverImageUrl = extractImageUrl(el.selectFirst("img")),
                            originalUrl = normalizeUrl(href, anoboyBaseUrl)
                        )
                    )
                }
            }
            shows
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun searchAnichin(query: String): List<Show> = withContext(Dispatchers.IO) {
        try {
            val doc = fetchDocument("$anichinBaseUrl/?s=${query}", getAnichinHeaders()) ?: return@withContext emptyList()
            val shows = mutableListOf<Show>()
            for (el in doc.select(".listupd .bs")) {
                val titleElement = el.selectFirst(".tt")
                val linkElement = el.selectFirst("a")
                val imgElement = el.selectFirst("img")
                if (titleElement != null && linkElement != null) {
                    val title = titleElement.selectFirst("h2")?.text()?.trim() ?: titleElement.text().trim()
                    val rawUrl = linkElement.attr("href")
                    shows.add(
                        Show(
                            id = rawUrl.hashCode().toLong(),
                            title = title.split(" Episode")[0].split(" Ep ")[0],
                            type = "donghua",
                            coverImageUrl = imgElement?.attr("src") ?: "",
                            originalUrl = normalizeUrl(rawUrl, anichinBaseUrl)
                        )
                    )
                }
            }
            shows
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getAnichinDailySchedule(day: String): List<Show> = withContext(Dispatchers.IO) {
        try {
            val doc = fetchDocument("$anichinBaseUrl/schedule/", getAnichinHeaders()) ?: return@withContext emptyList()
            val shows = mutableListOf<Show>()
            for (b in doc.select(".bixbox")) {
                val header = b.selectFirst(".releases h3")
                if (header != null && header.text().trim().equals(day, ignoreCase = true)) {
                    for (item in b.select(".bsx")) {
                        val a = item.selectFirst("a")
                        val img = item.selectFirst("img")
                        val title = a?.attr("title")?.trim() ?: ""
                        val linkUrl = a?.attr("href") ?: ""
                        if (title.isNotEmpty() && linkUrl.isNotEmpty()) {
                            shows.add(
                                Show(
                                    id = linkUrl.hashCode().toLong(),
                                    title = title,
                                    type = "donghua",
                                    coverImageUrl = img?.attr("src") ?: "",
                                    originalUrl = normalizeUrl(linkUrl, anichinBaseUrl)
                                )
                            )
                        }
                    }
                    break
                }
            }
            shows
        } catch (e: Exception) {
            emptyList()
        }
    }
}
