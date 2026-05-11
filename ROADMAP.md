# Rockxy Roadmap

Rockxy is an open-source native macOS debugging workflow platform for developers who need to inspect, understand, and shape network traffic with confidence.

This roadmap describes the public engineering direction for Rockxy. It is intentionally high-level, workflow-oriented, and not tied to fixed dates.

## Vision

Rockxy aims to be a thoughtful native macOS debugging tool for modern development workflows: fast capture, clear inspection, reliable HTTPS debugging, strong local privacy, and a desktop experience that feels at home on macOS.

The project values native macOS craftsmanship, debugging workflow quality, reliability, transparent engineering, and sustainable open-source development.

## How This Roadmap Works

This roadmap shows areas of active and planned public work. It does not represent a delivery promise, release schedule, or business roadmap.

- **Current Focus**: work receiving active attention.
- **Planned**: accepted public direction without a committed date.
- **Exploring**: areas being researched or shaped through community feedback.

For day-to-day execution, see the [Rockxy Public Roadmap](https://github.com/orgs/RockxyApp/projects/1) GitHub Project.

## Current Focus

- Improve Developer Setup workflows for Flutter, iOS, Android, React Native, backend runtimes, CLI tools, and container-based development.
- Strengthen certificate and HTTPS debugging guidance, including clearer trust-state recovery and safer setup instructions.
- Improve capture reliability, request-list performance, filtering behavior, and inspector responsiveness during real debugging sessions.
- Expand regression coverage for core workflows: capture start/stop, session persistence, inspector rendering, filtering, replay, and setup validation.
- Improve public documentation so new users can move from install to first useful capture with less guesswork.

## Workflow Priorities

### Stability And Reliability

- More predictable proxy start/stop behavior.
- Safer recovery when macOS proxy settings, helper state, or certificate trust are out of sync.
- Better handling of large captures and long-running debugging sessions.
- More durable transaction persistence, session restore, HAR import/export, and workflow continuity.

### Native macOS UX

- Continued refinement of window, tab, toolbar, keyboard, and inspector behavior.
- Better support for workspace-oriented debugging flows.
- Clearer feedback when capture, trust, helper, or setup state needs attention.
- Accessibility and keyboard-flow improvements where they improve real debugging work.

### Debugging Workflow Improvements

- Better filtering, search, grouping, and request-list ergonomics.
- Stronger replay, diff, rules, breakpoint, and scripting workflows.
- Improved WebSocket and GraphQL inspection.
- Exploration of gRPC and Protocol Buffers debugging workflows.
- Continued research into HTTP/2 and HTTP/3 behavior.

### Developer Setup

- Safer Flutter HTTPS guidance.
- Improved setup paths for mobile simulators, emulators, and physical devices.
- Clearer runtime-specific examples for Node.js, Python, Go, Ruby, Java, Docker, API clients, and CLI tools.
- Better validation language so Rockxy reports what it can verify without overstating device or runtime attribution.

### Documentation And Community

- Better onboarding for first-time users and contributors.
- Clearer troubleshooting for certificates, helper installation, capture issues, and platform-specific setup.
- More contributor-friendly issues, labels, and project-board visibility.
- [GitHub Discussions](https://github.com/RockxyApp/Rockxy/discussions) for questions, ideas, workflow feedback, and community examples.

## Exploring

These areas are public research topics, not committed release promises:

- gRPC and Protocol Buffers inspection workflows.
- HTTP/2 and HTTP/3 support.
- More protocol fixtures and sample apps for testing.
- Improved scripting diagnostics and examples.
- Better local workflow integrations that preserve Rockxy's privacy and local-first model.
- Contributor tooling for easier build, test, lint, and fixture workflows.

## Out Of Scope For This Public Roadmap

This roadmap does not include:

- Monetization plans.
- Enterprise strategy.
- Future paid features.
- Private infrastructure direction.
- Business operations.
- Competitive strategy.
- Sensitive security implementation details before responsible disclosure.
- Internal planning that is not ready for public discussion.

## Contributor Expectations

Contributions are welcome when they improve public Rockxy workflows: code, tests, documentation, reproducible bug reports, setup notes, protocol examples, and UX feedback.

Good public roadmap issues should explain:

- the debugging workflow being improved,
- the user-visible problem,
- the expected behavior,
- likely affected areas,
- useful validation steps.

Large or ambiguous work should start as a discussion or design issue before implementation.

## Transparency Notes

Rockxy tries to be transparent about public engineering direction without turning the roadmap into a promise list. Priorities can change when reliability, security, platform behavior, or user reports reveal more important work.

When an item is exploratory, it should remain labeled as exploratory until the implementation shape is understood.
