# API contract (Django + Django REST Framework)

The config documents in `design/config/` are the schema of record. Model them in Django, serialize
them back out in the same shape, and generate the Swift `Codable` structs from the OpenAPI schema
(`drf-spectacular` → `openapi-generator`) so the app and the API cannot drift.

## Suggested app layout
```
beemoo/
  accounts/       # User, AppleIdentity, auth views
  children/       # Child, Trial, progress aggregation
  catalog/        # Umbrella, Activity, Screen, Choice, Asset
  billing/        # Entitlement, StoreKit verification, ASSN webhook
  narration/      # TTS proxy + cache
```

## Models (the shape that matters)
```python
class Activity(models.Model):
    activity_id = models.SlugField(unique=True)      # "how-much"
    version = models.PositiveIntegerField(default=1)
    title = models.CharField(max_length=80)
    umbrella = models.SlugField()
    orientation = models.CharField(max_length=16, default="landscape")
    concepts = models.JSONField(default=list)
    status = models.CharField(max_length=16, default="stub")   # live | stub

class Screen(models.Model):
    activity = models.ForeignKey(Activity, related_name="screens", on_delete=models.CASCADE)
    n = models.PositiveIntegerField()
    type = models.CharField(max_length=16)   # intro|teaching|comparison|receptive|transition|celebration
    concept = models.CharField(max_length=32)
    payload = models.JSONField()             # type-specific fields, verbatim from the config
    audio = models.TextField(blank=True)
    class Meta:
        ordering = ["n"]
        unique_together = [("activity", "n")]

class Choice(models.Model):
    screen = models.ForeignKey(Screen, related_name="choices", on_delete=models.CASCADE)
    asset = models.ForeignKey("catalog.Asset", on_delete=models.PROTECT)
    meaning = models.CharField(max_length=32)   # semantic, NOT positional
    position = models.PositiveSmallIntegerField()  # authoring order only; client shuffles
```
Normalized in the database, **flattened in the response**. `payload` as JSONField is deliberate —
the six screen types have genuinely different fields and one table per type would be worse. Validate
`payload` per type with a serializer, not with columns.

## Endpoints

### Auth (`djangorestframework-simplejwt`)
`POST /v1/auth/apple/` — `{identityToken, authorizationCode}` → `{access, refresh, user}`
Verify the identity token against Apple's JWKS; key the user on `sub`, never the email.
`POST /v1/auth/email/` · `POST /v1/auth/refresh/`
Short-lived access token, refresh token in the iOS keychain.

### Catalog
`GET /v1/catalog/` → `activities.json` shape plus a per-activity `locked` flag computed from the
caller's entitlement. ETag + `Cache-Control`; this changes rarely. Use `prefetch_related` — it is
one query, not one per activity.

### Activity config
`GET /v1/activities/<slug>/` → one flattened document, exactly the shape of `config/how-much.json`.
Serializer nests screens and choices in a single response. Include `version`; the client caches by
`activity_id + version`. The client must never assemble an activity from multiple round-trips
mid-session.

### Assets
Content-hashed filenames served from object storage behind a CDN (`django-storages` + S3/CloudFront
or equivalent). Long, immutable `Cache-Control`. Django should not serve asset bytes in production.
Client caches as-you-go; an activity whose assets are already cached must run fully offline.

### Children and trials
`GET|POST /v1/children/` · `PATCH /v1/children/<id>/`
`POST /v1/children/<id>/trials/` — batched array of
`{clientTrialId, screenId, activityId, concept, firstTry, attempts, timestamp}`.
`clientTrialId` is a client-generated UUID with a `unique=True` column, so a retry after a failed
flush cannot double-count. Use `bulk_create(..., ignore_conflicts=True)`.

`GET /v1/children/<id>/progress/?window=week` → the aggregates the Progress screen renders.
Aggregate in the ORM (`Count`, `Avg` over `first_try`, grouped by concept); the client computes
nothing. Return every concept in the activity, including those with zero trials — the gaps are
clinically meaningful.

### Narration
`POST /v1/tts/` — `{text, voiceId}` → `{url, durationMs}`, cached server-side keyed on
`sha256(text + voice_id)`. Most prompts are fixed strings, so this is effectively a build-time
cache with a runtime path for name interpolation. Warm the cache with a management command
(`manage.py warm_tts how-much`) when an activity's copy changes.
The client **prefetches the whole activity's audio on open** — a per-screen round-trip mid-trial
breaks the pacing the trial flow depends on. Falls back to `AVSpeechSynthesizer` when unreachable.

### Subscriptions
`POST /v1/subscriptions/verify/` — signed StoreKit 2 transaction in, validated against the App
Store Server API, entitlement written.
`GET /v1/entitlements/`
`POST /v1/webhooks/appstore/` — App Store Server Notifications V2: renewals, cancellations,
refunds, billing retry. Verify the JWS signature chain before trusting anything. Process
asynchronously (Celery or django-q) and return 200 fast — Apple retries on slow responses.
Entitlement state is **server-owned**; the client's StoreKit read is an optimisation, not the truth.

## Conventions
- `camelCase` in JSON, `snake_case` in Python. Configure the renderer/parser to translate
  (`djangorestframework-camel-case`) rather than naming model fields in camelCase.
- Errors: `{"error": {"code": "...", "message": "..."}}` with real HTTP status codes. Wrap DRF's
  default exception handler once, globally.
- Version in the path (`/v1/`).
- `drf-spectacular` for the OpenAPI schema; the Swift client is generated from it, not hand-written.

## Seeding
Load `design/config/*.json` through a management command (`manage.py load_activity how-much`) so
the design workspace stays the origin of activity content. Do not hand-enter 36 screens in the
admin — round-trip them from the JSON and diff.
