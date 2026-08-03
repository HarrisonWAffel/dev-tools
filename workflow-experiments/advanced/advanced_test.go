package advanced

import "testing"

func Test_AdvancedTest1(t *testing.T) {
	if somethingMoreInteresting(true) != true {
		t.Errorf("Expected true, got false")
	}
}

func Test_AdvancedTest2(t *testing.T) {
	if somethingMoreInteresting(false) != false {
		t.Errorf("Expected false, got true")
	}
}

func Test_AdvancedTest3(t *testing.T) {
	if (somethingMoreInteresting(true) && somethingMoreInteresting(true)) != true {
		t.Errorf("Expected true, got false")
	}
}
