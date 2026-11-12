package full

func somethingThatOrchestratesOtherPackages(input bool) bool {
	return !input
}

func somethingnew(input string) string {
	return "new: " + input
}
