package enum TestError: Error, Equatable {
    case timedOut
    case scripted(String)
}
