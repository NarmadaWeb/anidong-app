package engine

import (
	"bytes"
	"os"
	"testing"
	"time"
)

func TestMultiLayerCache(t *testing.T) {
	dbPath := "test_cache.db"
	defer os.Remove(dbPath)

	cache, err := NewMultiLayerCache(10, dbPath)
	if err != nil {
		t.Fatalf("failed to create cache: %v", err)
	}
	defer cache.Close()

	key := "test_key"
	value := []byte("test_value")
	ttl := 2 * time.Second

	// Test Set
	err = cache.Set(key, value, ttl)
	if err != nil {
		t.Fatalf("failed to set cache: %v", err)
	}

	// Test Get (Memory)
	val, ok := cache.Get(key)
	if !ok || !bytes.Equal(val, value) {
		t.Errorf("expected %s, got %s", string(value), string(val))
	}

	// Clear memory cache to test Disk fallback
	cache.memoryCache.Remove(key)
	val, ok = cache.Get(key)
	if !ok || !bytes.Equal(val, value) {
		t.Errorf("disk fallback: expected %s, got %s", string(value), string(val))
	}

	// Test Expiration
	time.Sleep(3 * time.Second)
	_, ok = cache.Get(key)
	if ok {
		t.Errorf("expected cache to be expired")
	}
}

func TestCompression(t *testing.T) {
	data := []byte("this is some data that should be compressed and decompressed correctly")
	compressed, err := CompressData(data)
	if err != nil {
		t.Fatalf("compression failed: %v", err)
	}

	decompressed, err := DecompressData(compressed)
	if err != nil {
		t.Fatalf("decompression failed: %v", err)
	}

	if !bytes.Equal(data, decompressed) {
		t.Errorf("data mismatch after decompression")
	}
}

func BenchmarkCompression(b *testing.B) {
	data := []byte("random data for benchmarking compression performance")
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = CompressData(data)
	}
}

func BenchmarkCacheSet(b *testing.B) {
	dbPath := "bench_cache.db"
	defer os.Remove(dbPath)
	cache, _ := NewMultiLayerCache(100, dbPath)
	defer cache.Close()

	data := []byte("value")
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = cache.Set("key", data, time.Hour)
	}
}

func BenchmarkCacheGetMemory(b *testing.B) {
	dbPath := "bench_cache_get.db"
	defer os.Remove(dbPath)
	cache, _ := NewMultiLayerCache(100, dbPath)
	defer cache.Close()

	key := "key"
	_ = cache.Set(key, []byte("value"), time.Hour)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = cache.Get(key)
	}
}
