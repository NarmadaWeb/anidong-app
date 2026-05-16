package engine

import (
	"fmt"
	"sync"
	"time"

	lru "github.com/hashicorp/golang-lru/v2"
	"go.etcd.io/bbolt"
)

type CacheItem struct {
	Value      []byte
	Expiration int64
}

type MultiLayerCache struct {
	memoryCache *lru.Cache[string, *CacheItem]
	db          *bbolt.DB
	bucketName  []byte
	mu          sync.RWMutex
}

func NewMultiLayerCache(memorySize int, dbPath string) (*MultiLayerCache, error) {
	mem, err := lru.New[string, *CacheItem](memorySize)
	if err != nil {
		return nil, err
	}

	db, err := bbolt.Open(dbPath, 0600, &bbolt.Options{Timeout: 1 * time.Second})
	if err != nil {
		return nil, err
	}

	bucketName := []byte("cache")
	err = db.Update(func(tx *bbolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists(bucketName)
		return err
	})
	if err != nil {
		db.Close()
		return nil, err
	}

	return &MultiLayerCache{
		memoryCache: mem,
		db:          db,
		bucketName:  bucketName,
	}, nil
}

func (c *MultiLayerCache) Get(key string) ([]byte, bool) {
	// 1. Check memory cache
	if item, ok := c.memoryCache.Get(key); ok {
		if time.Now().Unix() < item.Expiration {
			return item.Value, true
		}
		c.memoryCache.Remove(key)
	}

	// 2. Check disk cache
	var value []byte
	var expiration int64
	var found bool = false

	err := c.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket(c.bucketName)
		data := b.Get([]byte(key))
		if data == nil {
			return nil
		}

		if len(data) < 8 {
			return nil
		}

		exp := int64(0)
		for i := 0; i < 8; i++ {
			exp |= int64(data[i]) << (8 * i)
		}

		if time.Now().Unix() >= exp {
			return nil // Expired
		}

		expiration = exp
		value = make([]byte, len(data)-8)
		copy(value, data[8:])
		found = true
		return nil
	})

	if err == nil && found {
		// Backfill memory cache
		c.memoryCache.Add(key, &CacheItem{
			Value:      value,
			Expiration: expiration,
		})
		return value, true
	}

	return nil, false
}

func (c *MultiLayerCache) Set(key string, value []byte, ttl time.Duration) error {
	expiration := time.Now().Add(ttl).Unix()
	item := &CacheItem{
		Value:      value,
		Expiration: expiration,
	}

	// Set memory cache
	c.memoryCache.Add(key, item)

	// Set disk cache
	return c.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket(c.bucketName)
		data := make([]byte, 8+len(value))
		for i := 0; i < 8; i++ {
			data[i] = byte(expiration >> (8 * i))
		}
		copy(data[8:], value)
		return b.Put([]byte(key), data)
	})
}

func (c *MultiLayerCache) Delete(key string) error {
	c.memoryCache.Remove(key)
	return c.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket(c.bucketName)
		return b.Delete([]byte(key))
	})
}

func (c *MultiLayerCache) Flush() error {
	c.memoryCache.Purge()
	return c.db.Update(func(tx *bbolt.Tx) error {
		err := tx.DeleteBucket(c.bucketName)
		if err != nil {
			return err
		}
		_, err = tx.CreateBucket(c.bucketName)
		return err
	})
}

func (c *MultiLayerCache) Close() error {
	return c.db.Close()
}

func (c *MultiLayerCache) GetStats() string {
	return fmt.Sprintf("Memory Items: %d, Bucket: %s", c.memoryCache.Len(), string(c.bucketName))
}
