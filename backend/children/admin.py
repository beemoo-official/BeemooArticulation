from django.contrib import admin
from .models import Child, Trial


@admin.register(Child)
class ChildAdmin(admin.ModelAdmin):
    list_display = ["name", "user", "created"]


@admin.register(Trial)
class TrialAdmin(admin.ModelAdmin):
    list_display = [
        "child", "activity_id", "stimulus_id", "target_word",
        "first_attempt_outcome", "retry_prompted", "timestamp",
    ]
    list_filter = ["activity_id", "first_attempt_outcome", "target_position"]
    date_hierarchy = "timestamp"
