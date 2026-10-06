# Spec: Login

## 1.1 Problem

Users cannot sign in with an email and a password.

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The system signs a user in with a valid email and password | P1 |
| FR-002 | The system locks the account after 5 failed attempts in 10 minutes | P2 |

## 1.2 Behavioral contract

```gherkin
@login
Feature: Sign in

  @FR-001 @P1
  Scenario: Valid credentials sign the user in
    Given a registered user
    When they submit a valid email and password
    Then they see their dashboard

  @FR-002 @P2
  Scenario: Repeated failures lock the account
    Given a registered user
    When they fail to sign in 5 times within 10 minutes
    Then the account is locked for 15 minutes
```

## 1.3 Out of scope

1. Social login.

## 1.4 Success criteria

| ID | Criterion | Scenario(s) |
|----|-----------|-------------|
| SC-001 | 95% of valid sign-ins finish in under 2 seconds | Valid credentials sign the user in |

## 1.5 Constraints & assumptions

1. Passwords are hashed with the existing library.

## Open questions

| # | Question | For | Blocks sprint? |
|---|----------|-----|----------------|
| 1 | None open | PO | no |
