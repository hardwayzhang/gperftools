// RPC基于key的排队功能 @hardwayzhang 2025.11.11
// 设计思路:类似餐厅叫号机制 优化并发粒度 https://iwiki.woa.com/p/4016433956
package rpc

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"

	"git.woa.com/GLib/GLib_proj/golang/app/pkg/xerror"
)

// QueueToken 排队令牌
type QueueToken struct {
	ID   uint32   // 排队序号
	done chan any // 排队唤醒通道
}

// 通知排队完成
func (t *QueueToken) notify() {
	if t.done != nil {
		close(t.done)
	}
}

// 等待排队通知
func (t *QueueToken) wait(ctx context.Context) error {
	if t.done != nil {
		select {
		case <-t.done:
		case <-ctx.Done():
			// 等待超时
			return xerror.NewError((int32)(xerror.ErrCode_RPC_WAIT_QUEUE_TIMEOUT), "wait timeout")
		}
	}
	return nil
}

// Queue 队列
type Queue struct {
	mu     sync.RWMutex
	head   uint32
	tail   uint32
	count  uint32
	key    uint64
	items  []*QueueToken
	cap    uint32
	active atomic.Bool // 队列非激活,token不需要入队列
}

// NewQueue 创建一个新的RPC队列
func NewQueue(key uint64, size uint32) *Queue {
	q := &Queue{
		key:   key,
		items: make([]*QueueToken, size),
		mu:    sync.RWMutex{},
		head:  0,
		tail:  0,
		count: 0,
		cap:   size,
	}
	q.active.Store(true)
	return q
}

// Push 队尾加入一个token
func (q *Queue) Push(token *QueueToken) error {
	q.mu.Lock()
	defer q.mu.Unlock()

	if q.count >= q.cap {
		return errors.New("queue is full")
	}

	q.items[q.tail] = token
	q.tail = (q.tail + 1) % q.cap
	q.count++

	if !q.active.Load() {
		q.active.Store(true)
	}

	return nil
}

// Pop 队首弹出token
func (q *Queue) Pop() (*QueueToken, error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	if q.count == 0 {
		return nil, errors.New("queue is empty")
	}

	token := q.items[q.head]
	q.items[q.head] = nil
	q.head = (q.head + 1) % q.cap
	q.count--
	if q.count == 0 && q.active.Load() {
		q.active.Store(false)
	}

	return token, nil
}

// Size 队列大小
func (q *Queue) Size() uint32 {
	q.mu.RLock()
	defer q.mu.RUnlock()
	return q.count
}

// IsActive 判断队列是否激活
func (q *Queue) IsActive() bool {
	return q.active.Load()
}

// SetActive 设置队列是否激活
func (q *Queue) SetActive(active bool) {
	q.active.Store(active)
}

// QueueMgr 队列管理器
type QueueMgr struct {
	mu        sync.RWMutex
	queueSize uint32
	queues    map[uint64]*Queue
}

// NewQueueMgr 创建一个队列管理器
func NewQueueMgr(size uint32) *QueueMgr {
	return &QueueMgr{
		queueSize: size,
		queues:    make(map[uint64]*Queue),
	}
}

// Acquire 分配一个排队号码 token
func (q *QueueMgr) Acquire(key uint64) (*QueueToken, error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	var err error

	queue, ok := q.queues[key]
	if !ok {
		// 空队列
		queue = NewQueue(key, q.queueSize)
		q.queues[key] = queue
		token := &QueueToken{
			ID:   0,
			done: nil,
		}
		return token, nil
	}

	if queue.IsActive() {
		// 队列激活正在处理请求,需要等待
		token := &QueueToken{
			ID:   queue.Size() + 1,
			done: make(chan any),
		}
		err = queue.Push(token)
		return token, err
	}

	// 队列没有激活,不需要等待
	token := &QueueToken{
		ID:   0,
		done: nil,
	}
	return token, nil
}

// Release 回收一个排队号码 token
func (q *QueueMgr) Release(key uint64) error {
	q.mu.RLock()
	defer q.mu.RUnlock()

	queue, ok := q.queues[key]
	if !ok {
		return errors.New("queue not found")
	}

	token, err := queue.Pop()
	if err != nil {
		return err
	}

	if token != nil {
		token.notify()
	}

	return nil
}
