// Narrow diagnostic accessor for the attended runtime-authority follow-up.
// The underlying flag remains transient state owned by CRBodyRuntime; this adds no
// persistence and exists only so the live failure reason can distinguish save/schema
// readiness from registration, session and running-state failures.
module CyberpunkRealism.Integration

@addMethod(CRBodyRuntime)
public func HasUnsupportedSaveVersion() -> Bool {
  return this.unsupportedSaveVersion;
}
