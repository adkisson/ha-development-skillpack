# Security & Secrets

- No secrets in YAML. Use `secrets.yaml` or environment variables.
- External calls (webhooks/APIs) must use secret tokens and avoid plaintext in code.
- Reviewers grep for `token|api_key|Bearer|https?://` in diffs.
- PRs touching credentials require owner review and must not include real values even in comments.
