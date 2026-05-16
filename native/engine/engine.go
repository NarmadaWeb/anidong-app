package engine

import (
	"fmt"
	"time"
)

// Engine is the main structure exported to Flutter via gomobile
type Engine struct {
	cache *MultiLayerCache
}

// NewEngine initializes the native engine with a cache
func NewEngine(dbPath string) (*Engine, error) {
	cache, err := NewMultiLayerCache(1000, dbPath)
	if err != nil {
		return nil, err
	}
	return &Engine{cache: cache}, nil
}

// GetOrCompute is the main pattern for high performance data retrieval
func (e *Engine) GetOrCompute(key string, ttlSeconds int, taskType string, input []byte, callback Callback) {
	// Offload to worker pool to avoid blocking the calling thread
	_ = workerPool.Submit(func() {
		// 1. Try Cache
		if val, ok := e.cache.Get(key); ok {
			callback.OnSuccess(val)
			return
		}

		// 2. Compute
		var result []byte
		var err error

		switch taskType {
		case "compress":
			result, err = CompressData(input)
		case "json":
			result, err = ProcessLargeJSON(input)
		default:
			err = fmt.Errorf("unknown task type: %s", taskType)
		}

		if err != nil {
			callback.OnError(err.Error())
			return
		}

		// 3. Store in Cache
		_ = e.cache.Set(key, result, time.Duration(ttlSeconds)*time.Second)

		// 4. Return
		callback.OnSuccess(result)
	})
}

// Callback interface for async results in gomobile
type Callback interface {
	OnSuccess(data []byte)
	OnError(err string)
}

// FlushCache clears all cached data
func (e *Engine) FlushCache() {
	_ = e.cache.Flush()
}

// GetStats returns cache statistics
func (e *Engine) GetStats() string {
	return e.cache.GetStats()
}

// Close cleans up resources
func (e *Engine) Close() {
	_ = e.cache.Close()
}
