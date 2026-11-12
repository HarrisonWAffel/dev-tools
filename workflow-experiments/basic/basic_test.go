package basic

import "testing"

func Test_BasicTest1(t *testing.T) {
	if somethingSimple() != false {
		t.Errorf("Expected false, got true")
	}
}

func Test_BasicTest2(t *testing.T) {
	if somethingSimple() == true {
		t.Errorf("Expected true, got false")
	}
}

func Test_BasicTest3(t *testing.T) {
	if (somethingSimple() && somethingSimple()) != false {
		t.Errorf("Expected false, got true")
	}
}

func Test_BasicTest4(t *testing.T) {
	if somethingNew() != true {
		t.Errorf("Expected true, got false")
	}
}
