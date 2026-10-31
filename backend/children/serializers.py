from rest_framework import serializers
from .models import Child, Trial


class ChildSerializer(serializers.ModelSerializer):
    class Meta:
        model = Child
        fields = ["id", "name", "created"]
        read_only_fields = ["id", "created"]


class TrialSerializer(serializers.ModelSerializer):
    clientTrialId = serializers.UUIDField(source="client_trial_id")
    activityId = serializers.SlugField(source="activity_id")
    screenId = serializers.IntegerField(source="screen_id")
    stimulusId = serializers.SlugField(source="stimulus_id", required=False, allow_blank=True)
    targetWord = serializers.CharField(source="target_word")
    targetPosition = serializers.CharField(source="target_position", required=False, allow_blank=True)
    stimulusType = serializers.CharField(source="stimulus_type")
    firstAttemptOutcome = serializers.CharField(source="first_attempt_outcome")
    retryPrompted = serializers.BooleanField(source="retry_prompted", default=False)
    retryOutcome = serializers.CharField(source="retry_outcome", required=False, allow_blank=True)

    class Meta:
        model = Trial
        fields = [
            "clientTrialId", "activityId", "level", "screenId",
            "stimulusId", "targetWord", "targetPosition", "stimulusType",
            "firstAttemptOutcome", "retryPrompted", "retryOutcome",
            "attempts", "timestamp",
        ]

    def create(self, validated_data):
        validated_data["child"] = self.context["child"]
        return Trial.objects.update_or_create(
            client_trial_id=validated_data["client_trial_id"],
            defaults=validated_data,
        )[0]


class ProgressSerializer(serializers.Serializer):
    activityId = serializers.CharField()
    level = serializers.IntegerField(allow_null=True)
    totalTrials = serializers.IntegerField()
    correctFirst = serializers.IntegerField()
    accuracy = serializers.FloatField()
