import XCTest
import Combine
@testable import Pythonst3

final class PythonRuntimeTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testEmbeddedPythonExecutesAndCapturesOutput() {
        let runtime = PythonRuntime.shared

        let ready = expectation(description: "Python runtime becomes ready")
        ready.assertForOverFulfill = false
        var failureMessage: String?

        runtime.$state
            .receive(on: RunLoop.main)
            .sink { state in
                switch state {
                case .ready:
                    ready.fulfill()
                case .failed(let message):
                    failureMessage = message
                    ready.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        runtime.prepare()
        wait(for: [ready], timeout: 60)
        XCTAssertNil(failureMessage, failureMessage ?? "")

        let output = expectation(description: "print output captured")
        output.assertForOverFulfill = false

        runtime.$lines
            .receive(on: RunLoop.main)
            .sink { lines in
                if lines.contains(where: { $0.text.contains("PYTHONST3_SMOKE_OK") }) {
                    output.fulfill()
                }
            }
            .store(in: &cancellables)

        runtime.run(
            source: "print('PYTHONST3_SMOKE_OK')\nprint(2 + 2)\n",
            filename: "smoke.py",
            projectURL: FileManager.default.temporaryDirectory,
            timeout: 20
        )

        wait(for: [output], timeout: 30)
        XCTAssertTrue(runtime.lines.contains(where: { $0.text.contains("PYTHONST3_SMOKE_OK") }))
    }
}
