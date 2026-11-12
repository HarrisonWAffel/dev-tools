package integration

import "testing"

func Test_Integration1(t *testing.T) {
	if Integration() != 1 {
		t.Error("Integration() should return 1")
	}
}

func Test_Integration2(t *testing.T) {
	if Integration()+1 != 2 {
		t.Error("Integration() should return 2")
	}
}

func Test_Integration3(t *testing.T) {
	if Integration()-1 != 100000 {
		t.Error("Integration() should return 0")
	}
}
