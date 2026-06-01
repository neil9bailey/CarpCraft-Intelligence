# 10 Testing Strategy

## Backend

- Unit test deterministic rules.
- Test health and version endpoints.
- Test persistent CRUD routes with SQLite dependency overrides.
- Test Lake Brain counts from normalized sessions, catches and blank intervals.
- Add route contract tests as persistence arrives.
- Add regression tests for confidence caps and fish welfare warnings.

Current command:

```powershell
cd backend
python -m pytest
```

## Mobile

- Widget test app startup.
- Add navigation tests for critical flows.
- Add form validation tests when state management is introduced.

Current command:

```powershell
cd mobile\carpcraft_app
flutter test
```

## Product Validation

- Use sample winter, spring and hot summer sessions.
- Confirm blanks are visible in pattern review.
- Confirm recommendations never guarantee catches.
- Confirm weak data suppresses confidence.
