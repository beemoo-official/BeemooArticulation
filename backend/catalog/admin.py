from django.contrib import admin
from .models import Umbrella, Activity, Screen, Stimulus, FlashcardGroup, FlashcardOrder


@admin.register(Umbrella)
class UmbrellaAdmin(admin.ModelAdmin):
    list_display = ["key", "title", "sort_order"]
    ordering = ["sort_order"]


class ScreenInline(admin.TabularInline):
    model = Screen
    extra = 0
    fields = ["n", "type", "concept"]
    ordering = ["n"]


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ["activity_id", "title", "umbrella", "status", "sort_order"]
    list_filter = ["umbrella", "status"]
    inlines = [ScreenInline]


@admin.register(Screen)
class ScreenAdmin(admin.ModelAdmin):
    list_display = ["activity", "n", "type", "concept"]
    list_filter = ["type", "activity"]


@admin.register(Stimulus)
class StimulusAdmin(admin.ModelAdmin):
    list_display = ["stimulus_id", "target_word", "target_position", "target_sound"]
    list_filter = ["target_position", "target_sound"]


class FlashcardOrderInline(admin.TabularInline):
    model = FlashcardOrder
    extra = 0


@admin.register(FlashcardGroup)
class FlashcardGroupAdmin(admin.ModelAdmin):
    list_display = ["slug", "title", "target_sound", "target_position"]
    inlines = [FlashcardOrderInline]
