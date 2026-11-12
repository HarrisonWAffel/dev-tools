package full

import "testing"

func Test_somethingNew(t *testing.T) {
	expected := "new: test"
	result := somethingnew("test")
	if result != expected {
		t.Errorf("expected %s, got %s", expected, result)
	}
}
