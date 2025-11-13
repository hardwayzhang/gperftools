package xerror

import "fmt"

// ErrCode_RPC_WAIT_QUEUE_TIMEOUT is a placeholder error code used for queue wait timeouts in tests.
const ErrCode_RPC_WAIT_QUEUE_TIMEOUT = 1001

// Error represents a minimal error type with a code and message.
type Error struct {
	Code int32
	Msg  string
}

func (e *Error) Error() string {
	return fmt.Sprintf("code=%d msg=%s", e.Code, e.Msg)
}

// NewError constructs a new Error with the provided code and message.
func NewError(code int32, msg string) error {
	return &Error{Code: code, Msg: msg}
}
