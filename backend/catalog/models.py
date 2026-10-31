from django.db import models


class Umbrella(models.Model):
    key = models.SlugField(unique=True)
    title = models.CharField(max_length=80)
    desc = models.TextField()
    icon = models.CharField(max_length=64)
    tint = models.CharField(max_length=7)
    ink = models.CharField(max_length=7)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order"]

    def __str__(self):
        return self.title


class Activity(models.Model):
    activity_id = models.SlugField(unique=True)
    version = models.PositiveIntegerField(default=1)
    title = models.CharField(max_length=80)
    umbrella = models.ForeignKey(
        Umbrella, to_field="key", on_delete=models.CASCADE, related_name="activities"
    )
    orientation = models.CharField(max_length=16, default="landscape")
    concepts = models.JSONField(default=list)
    status = models.CharField(max_length=16, default="stub")
    is_new = models.BooleanField(default=False)
    initials = models.CharField(max_length=4)
    tint = models.CharField(max_length=7)
    desc = models.TextField(blank=True)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order"]

    def __str__(self):
        return self.title


class Screen(models.Model):
    activity = models.ForeignKey(
        Activity, related_name="screens", on_delete=models.CASCADE,
        to_field="activity_id"
    )
    n = models.PositiveIntegerField()
    type = models.CharField(max_length=24)
    concept = models.CharField(max_length=64)
    payload = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["n"]
        unique_together = [("activity", "n")]

    def __str__(self):
        return f"{self.activity_id} screen {self.n} ({self.type})"


class Stimulus(models.Model):
    stimulus_id = models.SlugField(unique=True)
    target_word = models.CharField(max_length=64)
    target_position = models.CharField(max_length=16)
    target_sound = models.CharField(max_length=8, default="s")
    word_image = models.CharField(max_length=128)
    sentence_text = models.CharField(max_length=256, blank=True)
    sentence_image = models.CharField(max_length=128, blank=True)
    audio_word = models.CharField(max_length=128, blank=True)
    audio_sentence = models.CharField(max_length=128, blank=True)

    class Meta:
        ordering = ["stimulus_id"]

    def __str__(self):
        return f"{self.stimulus_id}: {self.target_word}"


class FlashcardGroup(models.Model):
    slug = models.SlugField(unique=True)
    title = models.CharField(max_length=64)
    target_sound = models.CharField(max_length=8)
    target_position = models.CharField(max_length=16)
    stimuli = models.ManyToManyField(Stimulus, through="FlashcardOrder")

    def __str__(self):
        return self.title


class FlashcardOrder(models.Model):
    group = models.ForeignKey(FlashcardGroup, on_delete=models.CASCADE)
    stimulus = models.ForeignKey(Stimulus, on_delete=models.CASCADE)
    position = models.PositiveIntegerField()

    class Meta:
        ordering = ["position"]
        unique_together = [("group", "position")]
