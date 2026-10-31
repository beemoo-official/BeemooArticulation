from rest_framework import serializers
from .models import Umbrella, Activity, Screen, Stimulus, FlashcardGroup, FlashcardOrder


class UmbrellaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Umbrella
        fields = ["key", "title", "desc", "icon", "tint", "ink"]


class ActivityListSerializer(serializers.ModelSerializer):
    """Compact activity representation for the catalog list."""
    id = serializers.CharField(source="activity_id")
    umbrella = serializers.SlugRelatedField(slug_field="key", read_only=True)
    name = serializers.CharField(source="title")
    isNew = serializers.BooleanField(source="is_new")

    class Meta:
        model = Activity
        fields = ["id", "umbrella", "name", "desc", "initials", "tint", "status", "isNew"]


class ScreenSerializer(serializers.ModelSerializer):
    """Flattens the payload JSONField into the top-level screen dict."""

    class Meta:
        model = Screen
        fields = ["n", "type", "concept", "payload"]

    def to_representation(self, instance):
        data = {
            "n": instance.n,
            "type": instance.type,
            "concept": instance.concept,
        }
        if instance.payload:
            data.update(instance.payload)
        return data


class ActivityConfigSerializer(serializers.ModelSerializer):
    """Full activity config matching the iOS ActivityConfig JSON shape."""
    activityId = serializers.CharField(source="activity_id")
    umbrella = serializers.SlugRelatedField(slug_field="key", read_only=True)
    screens = ScreenSerializer(many=True, read_only=True)

    class Meta:
        model = Activity
        fields = ["activityId", "version", "title", "umbrella", "orientation", "concepts", "screens"]


class CatalogSerializer(serializers.Serializer):
    """Top-level catalog: umbrellas + activities."""
    version = serializers.IntegerField(default=1)
    umbrellas = UmbrellaSerializer(many=True)
    activities = ActivityListSerializer(many=True)


class StimulusSerializer(serializers.ModelSerializer):
    stimulusId = serializers.CharField(source="stimulus_id")
    targetWord = serializers.CharField(source="target_word")
    targetPosition = serializers.CharField(source="target_position")
    targetSound = serializers.CharField(source="target_sound")
    wordImage = serializers.CharField(source="word_image")
    sentenceText = serializers.CharField(source="sentence_text")
    sentenceImage = serializers.CharField(source="sentence_image")

    class Meta:
        model = Stimulus
        fields = [
            "stimulusId", "targetWord", "targetPosition", "targetSound",
            "wordImage", "sentenceText", "sentenceImage",
        ]


class FlashcardGroupSerializer(serializers.ModelSerializer):
    stimuli = serializers.SerializerMethodField()

    class Meta:
        model = FlashcardGroup
        fields = ["slug", "title", "target_sound", "target_position", "stimuli"]

    def get_stimuli(self, obj):
        orders = FlashcardOrder.objects.filter(group=obj).select_related("stimulus").order_by("position")
        return StimulusSerializer([o.stimulus for o in orders], many=True).data
