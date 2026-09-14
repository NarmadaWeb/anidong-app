package com.narmadaweb.anidong.data.services

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.jsoup.Jsoup

class ScrapingServiceTest {

    @Test
    fun testFindAnichinListupdNewStructure() {
        val html = """
            <div class="bixbox">
                <h2>Rilisan Terbaru</h2>
                <div class="listupd">Target List</div>
            </div>
        """.trimIndent()
        val doc = Jsoup.parse(html)
        val scrapingService = ScrapingService()
        val element = scrapingService.findAnichinListupd(doc, listOf("rilisan terbaru"))
        assertNotNull(element)
        assertEquals("Target List", element?.text()?.trim())
    }

    @Test
    fun testAnichinServerExtraction() {
        val html = """
            <div class="mirror">
                <select>
                    <option value="https://example.com/embed1">Server 1</option>
                    <option value="https://example.com/embed2">Server 2</option>
                </select>
            </div>
        """.trimIndent()
        val doc = Jsoup.parse(html)
        val scrapingService = ScrapingService()
        val servers = scrapingService.extractAnichinServers(doc)
        assertEquals(2, servers.size)
        assertEquals("Server 1", servers[0]["name"])
        assertEquals("https://example.com/embed1", servers[0]["url"])
    }
}
