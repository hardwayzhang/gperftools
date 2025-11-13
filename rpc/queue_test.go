package rpc

import (
	"context"
	"testing"
	"time"
)

func TestQueueMgrAcquireFirstRequest(t *testing.T) {
	mgr := NewQueueMgr(4)

	token, err := mgr.Acquire(101)
	if err != nil {
		t.Fatalf("Acquire returned unexpected error: %v", err)
	}
	if token == nil {
		t.Fatal("expected non-nil token")
	}
	if token.ID != 0 {
		t.Fatalf("expected token ID 0 for first request, got %d", token.ID)
	}
	if token.done != nil {
		t.Fatal("expected first token to have nil wait channel")
	}

	mgr.mu.RLock()
	queue := mgr.queues[101]
	mgr.mu.RUnlock()
	if queue == nil {
		t.Fatal("expected queue to be created for key 101")
	}
	if queue.Size() != 0 {
		t.Fatalf("expected queue size 0 after first acquire, got %d", queue.Size())
	}
	if !queue.IsActive() {
		t.Fatal("expected queue to be active after first acquire")
	}
}

func TestQueueMgrAcquireWhileActiveEnqueues(t *testing.T) {
	mgr := NewQueueMgr(4)
	if _, err := mgr.Acquire(202); err != nil {
		t.Fatalf("first acquire failed: %v", err)
	}

	token, err := mgr.Acquire(202)
	if err != nil {
		t.Fatalf("second acquire failed: %v", err)
	}
	if token.ID != 1 {
		t.Fatalf("expected second token ID 1, got %d", token.ID)
	}
	if token.done == nil {
		t.Fatal("expected queued token to have wait channel")
	}
	select {
	case <-token.done:
		t.Fatal("queued token should not be notified before release")
	default:
	}

	mgr.mu.RLock()
	size := mgr.queues[202].Size()
	mgr.mu.RUnlock()
	if size != 1 {
		t.Fatalf("expected queue size 1 after enqueue, got %d", size)
	}
}

func TestQueueMgrReleaseNotifiesNextToken(t *testing.T) {
	mgr := NewQueueMgr(4)
	if _, err := mgr.Acquire(303); err != nil {
		t.Fatalf("first acquire failed: %v", err)
	}
	waitToken, err := mgr.Acquire(303)
	if err != nil {
		t.Fatalf("second acquire failed: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	done := make(chan error, 1)
	go func() {
		done <- waitToken.wait(ctx)
	}()

	if err := mgr.Release(303); err != nil {
		t.Fatalf("release failed: %v", err)
	}

	select {
	case waitErr := <-done:
		if waitErr != nil {
			t.Fatalf("wait returned unexpected error: %v", waitErr)
		}
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for queued token to be notified")
	}

	mgr.mu.RLock()
	queue := mgr.queues[303]
	mgr.mu.RUnlock()
	if queue == nil {
		t.Fatal("expected queue to remain allocated")
	}
	if queue.Size() != 0 {
		t.Fatalf("expected queue to be empty after release, got %d", queue.Size())
	}
	if queue.IsActive() {
		t.Fatal("expected queue to be inactive after draining all waiters")
	}
}

func TestQueueMgrAcquireWhenQueueFull(t *testing.T) {
	mgr := NewQueueMgr(1)
	if _, err := mgr.Acquire(404); err != nil {
		t.Fatalf("first acquire failed: %v", err)
	}
	if _, err := mgr.Acquire(404); err != nil {
		t.Fatalf("second acquire should enqueue successfully, got error: %v", err)
	}
	if _, err := mgr.Acquire(404); err == nil {
		t.Fatal("expected error when queue is full, got nil")
	} else if err.Error() != "queue is full" {
		t.Fatalf("expected 'queue is full' error, got %v", err)
	}
}
