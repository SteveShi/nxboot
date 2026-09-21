# Security Policy

## Supported Versions

We provide security updates and patches for the following versions:

| Version | Supported |
| :--- | :--- |
| 2.x.x | ✅ Supported |
| < 2.0.0 | ❌ Not Supported |

Please ensure you are running the latest supported release to receive active security fixes.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately rather than opening a public issue.

1. **GitHub Private Vulnerability Reporting (Preferred)**: Navigate to the [Security Tab](https://github.com/SteveShi/nxboot/security) of this repository and click **"Report a vulnerability"**.
2. **Email**: If you prefer direct email or cannot use GitHub Security Advisories, contact [xuanlian@mac.com](mailto:xuanlian@mac.com).

### Information to Include

To help us triage and resolve the issue quickly, please include:
- A detailed description of the vulnerability and its potential impact.
- Affected version(s) and environment details (macOS version, Xcode version, architecture).
- Clear, reproducible step-by-step instructions or a minimal Proof of Concept (PoC).

## Response Process

- **Acknowledgement**: We will acknowledge receipt of your report within 48 hours.
- **Investigation**: We will investigate and assess severity.
- **Fix & Disclosure**: We will prepare a security patch and coordinate a coordinated disclosure or release notes update. Please allow reasonable time to remediate before public disclosure.

---

## Hardware Interface Safety

- **USB Communication Boundary**: Raw USB transfers via IOKit are bounds-checked to prevent arbitrary host buffer corruptions.
- **Payload Validation**: Payloads are validated for integrity before dispatching over USB endpoints.
