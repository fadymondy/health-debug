import Testing
@testable import HealthDebugKit

@Test func versionIsSet() {
    #expect(HealthDebugKit.version == "1.0.0")
}

@Test func appNameIsCorrect() {
    #expect(HealthDebugKit.appName == "Health Debug")
}
