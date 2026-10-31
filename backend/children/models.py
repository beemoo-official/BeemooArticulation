import uuid
from django.conf import settings
from django.db import models


class Child(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="children"
    )
    name = models.CharField(max_length=64)
    created = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Trial(models.Model):
    client_trial_id = models.UUIDField(unique=True, default=uuid.uuid4)
    child = models.ForeignKey(Child, related_name="trials", on_delete=models.CASCADE)
    activity_id = models.SlugField()
    level = models.PositiveSmallIntegerField(null=True, blank=True)
    screen_id = models.PositiveIntegerField()
    stimulus_id = models.SlugField(blank=True)
    target_word = models.CharField(max_length=64)
    target_position = models.CharField(max_length=16, blank=True)
    stimulus_type = models.CharField(max_length=16)
    first_attempt_outcome = models.CharField(max_length=16)
    retry_prompted = models.BooleanField(default=False)
    retry_outcome = models.CharField(max_length=16, blank=True)
    attempts = models.PositiveIntegerField(default=1)
    timestamp = models.DateTimeField()
    synced_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-timestamp"]

    def __str__(self):
        return f"{self.child.name} – {self.stimulus_id} ({self.first_attempt_outcome})"
