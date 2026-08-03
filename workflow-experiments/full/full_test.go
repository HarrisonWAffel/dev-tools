package full

import "testing"

func Test_Full1(t *testing.T) {
	x := somethingBig()
	if x != 9 {
		t.Errorf("somethingBig() = %d, want 9", x)
	}
}
