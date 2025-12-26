# Attach telemetry logger for integration tests
Legion.Test.TelemetryLogger.attach()

ExUnit.configure(exclude: [:integration])
ExUnit.start()
