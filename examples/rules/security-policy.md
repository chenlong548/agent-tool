# Security Policy (agent-enforced)

A project-level security policy written to be **executed by AI agents**, not shelved in a wiki.
It is loaded as a rule file so that every code generation and review pass is measured against it.

> Drop this at `.agents/rules/security-policy.md` (or your tool's equivalent rule path) and reference
> it from `AGENTS.md`. Agents treat it as a hard constraint, not background reading.

---

## 1. Security objectives

- Protect systems and data
- Prevent unauthorised access
- Preserve data integrity
- Maintain availability
- Meet applicable compliance requirements

---

## 2. Responsibility split

Prescribing *who* owns what is what makes a policy enforceable. An unassigned rule is not a rule.

### 2.1 Development
- Follow the secure coding standard
- Take part in security training
- Fix vulnerabilities in a timely manner
- Submit to security review

### 2.2 Security (dedicated role)
- Conduct security audits
- Detect vulnerabilities
- Assess security risk
- Provide remediation guidance
- Own and evolve this policy

### 2.3 Operations
- Configure hardened environments
- Monitor for security events
- Respond to incidents
- Maintain backups

---

## 3. Secure coding standard

### 3.1 Input validation
- Validate **all** external input
- Use parameterised queries — never string-concatenate SQL
- Escape special characters at the correct layer
- Enforce maximum input length

### 3.2 Authentication and authorisation
- Enforce a strong password policy
- Support multi-factor authentication
- Apply least privilege
- Rotate credentials on a schedule

> **Enforcement note.** Authentication must be *verifiably* enforced at the request boundary.
> A configured environment variable, a log line saying `auth required`, or a middleware that is
> registered but never reached does not constitute enforcement. Reviewers must confirm that an
> unauthenticated request is actually **rejected**.

### 3.3 Cryptography
- Use HTTPS for all transport
- Encrypt sensitive data at rest
- Use modern, vetted algorithms
- Rotate keys

### 3.4 Error handling
- Never expose internal detail to end users
- Log errors with enough context to diagnose
- Fail safe, not open
- Avoid information leakage through timing or error text

### 3.5 Dependency management
- Update dependencies deliberately
- Scan for known vulnerabilities
- Pin versions
- Remove dependencies with unresolved high-severity issues

---

## 4. Security testing

### 4.1 Test types
- Penetration testing
- Vulnerability scanning
- Code audit
- Security function testing

### 4.2 Process
1. Define the security test plan
2. Execute
3. Analyse results
4. Remediate
5. Verify the fix

### 4.3 Tooling
- OWASP ZAP — dynamic scanning
- Nmap — network surface
- Burp Suite — request-level manual testing
- SonarQube — static analysis

---

## 5. Incident response

### 5.1 Flow
1. Detect
2. Assess impact
3. Contain
4. Investigate root cause
5. Remediate
6. Document

### 5.2 Containment actions
- Isolate affected systems
- Terminate anomalous processes
- Rotate affected credentials
- Back up critical data

### 5.3 Post-incident
- Root-cause analysis
- Assess whether existing controls worked
- Update this policy
- Run targeted training

> **Credential rule.** Any credential that has been committed to a repository — even a private one —
> is considered compromised. **Rotate it; do not merely delete the file.** History is not a security
> boundary.

---

## 6. Configuration hardening

### 6.1 Server
- Disable unused services
- Define firewall rules explicitly
- Enable logging
- Patch on a schedule

### 6.2 Application
- Safe session management
- Explicit CORS policy — avoid wildcard origins
- Content Security Policy enabled
- Secure HTTP response headers

### 6.3 Database
- Restrict access permissions
- Encrypt sensitive columns
- Back up on a schedule
- Enable audit logging

---

## 7. Security audit

### 7.1 Scope
- Code security review
- Configuration review
- Permission review
- Log review

### 7.2 Frequency
- Per commit — automated checks
- Monthly — system audit
- Quarterly — full audit
- Annually — comprehensive audit

### 7.3 Reporting
- Record findings
- Provide remediation guidance
- Track remediation progress
- Measure improvement

---

## 8. Training

### 8.1 Content
- Secure coding standard
- Common vulnerability classes
- Security testing methods
- Incident response

### 8.2 Frequency
- Onboarding
- Quarterly
- Annual awareness
- Targeted, after an incident

### 8.3 Effectiveness
- Knowledge checks
- Code review outcomes
- Assessment of practice
- Collected feedback

---

## 9. Compliance

### 9.1 Applicable regimes
- Data protection regulation in the operating jurisdiction
- Contractual security obligations
- Relevant industry standards (e.g. OWASP ASVS, ISO 27001)

### 9.2 Checks
- Periodic compliance assessment
- Record compliance status
- Remediate gaps
- Produce compliance reporting

---

## 10. Standing practices

- Least privilege, always
- Defence in depth
- Assess regularly
- Keep security visible
- Update controls as threats change
- Build a security culture
- Improve the process continuously
- Stay connected to the security community
