package engine

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"io"
	"sync"

	"github.com/panjf2000/ants/v2"
)

var (
	// Pool for gzip writers to reduce heap allocations
	gzipWriterPool = sync.Pool{
		New: func() interface{} {
			return gzip.NewWriter(nil)
		},
	}

	// Pool for byte buffers
	bufferPool = sync.Pool{
		New: func() interface{} {
			return new(bytes.Buffer)
		},
	}

	// Goroutine pool to limit concurrency
	workerPool *ants.Pool
)

func init() {
	var err error
	workerPool, err = ants.NewPool(20) // Limit to 20 concurrent tasks
	if err != nil {
		panic(err)
	}
}

// CompressData compresses input using gzip with pool optimization
func CompressData(data []byte) ([]byte, error) {
	buf := bufferPool.Get().(*bytes.Buffer)
	buf.Reset()
	defer bufferPool.Put(buf)

	gw := gzipWriterPool.Get().(*gzip.Writer)
	gw.Reset(buf)
	defer gzipWriterPool.Put(gw)

	_, err := gw.Write(data)
	if err != nil {
		return nil, err
	}

	err = gw.Close()
	if err != nil {
		return nil, err
	}

	return append([]byte(nil), buf.Bytes()...), nil
}

// DecompressData decompresses input using gzip
func DecompressData(data []byte) ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	return io.ReadAll(reader)
}

// ProcessLargeJSON simulates heavy JSON parsing and transformation
func ProcessLargeJSON(input []byte) ([]byte, error) {
	var data interface{}
	err := json.Unmarshal(input, &data)
	if err != nil {
		return nil, err
	}

	// Simulate some transformation
	transformed, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	return transformed, nil
}
